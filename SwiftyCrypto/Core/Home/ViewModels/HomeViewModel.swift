//
//  HomeViewModel.swift
//  SwiftyCrypto
//
//  Created by varunbhalla19 on 24/12/22.
//

import Foundation

class HomeViewModel: ObservableObject {
    
    @Published var allCoins: [Coin] = .init()
    @Published var portfolioCoins: [Coin] = .init()
    @Published var searchText = ""
    @Published var statistics: [Statistics] = .init()
    @Published var isReloading = false
    
    private let service: CoinService = CoinService()
    private let marketService: MarketService = MarketService()
    private let dataService: PortfolioDataService = PortfolioDataService()
    
    init() {
        subscribeToCoins()
    }
    
    func subscribeToCoins(){
        service.$allCoins
            .combineLatest($searchText)
            .debounce(for: .seconds(0.6), scheduler: DispatchQueue.main)
            .map { (coins, text) in
                if text.isEmpty { return coins }
                return coins.filter { coin in
                    coin.name.lowercased().contains(text.lowercased().trimmingCharacters(in: .whitespaces)) ||
                    coin.symbol.lowercased().contains(text.lowercased().trimmingCharacters(in: .whitespaces)) ||
                    coin.id.lowercased().contains(text.lowercased().trimmingCharacters(in: .whitespaces))
                }
            }.assign(to: &$allCoins)

        $allCoins
            .combineLatest(dataService.$portfolio)
            .compactMap { (coins: [Coin], portfolios: [Portfolio]) -> [Coin] in
                coins.compactMap { coin in
                    guard let folio = portfolios.first(where: { $0.coinId == coin.id }) else { return nil }
                    return coin.updateHoldings(with: folio.amount)
                }
            }
//            .removeDuplicates(by: { coins1, coins2 in coins1.isEmpty && coins2.isEmpty })
            .assign(to: &$portfolioCoins)

        marketService.$marketData
            .combineLatest($portfolioCoins)
            .map { marketData, coins in
                var stats: [Statistics] = .init()
                guard let marketData else {return stats}
                
                let portfolioValue = coins.map { $0.currentHoldingsValue }.reduce(0, +)
                
                let previousValue = coins.map { coin in
                    let priceChange = coin.priceChangePercentage24H ?? 0.0
                    return coin.currentHoldingsValue / (1 + ( priceChange / 100))
                }.reduce(0.0, +)
                
                let percentDiff = ((portfolioValue - previousValue) / previousValue) * 100
                
                stats.append(contentsOf: [
                    .init(title: "Market Cap", value: marketData.marketCap, percentChange: marketData.marketCapChangePercentage24HUsd),
                    .init(title: "24h Volume", value: marketData.volume),
                    .init(title: "BTC Dominance", value: marketData.btcDominance),
                    .init(title: "Portfolio", value: portfolioValue.asCurrencyWith2, percentChange: percentDiff)
                ])
                
                return stats
            }.assign(to: &$statistics)
        
        $allCoins
            .combineLatest(marketService.$marketData)
            .map { coins, marketService in false }
            .assign(to: &$isReloading)
        
    }
    
    func updateFolio(coin: Coin, amount: Double) {
        dataService.update(coin: coin, with: amount)
    }
  
    var personalisedCoinsList: [Coin] {
        portfolioCoins + allCoins.filter{ coin in !portfolioCoins.contains { $0.id == coin.id } }
    }
    
    func reloadData() {
        isReloading = true
        service.getCoins()
        marketService.getData()
        HapticManager.notify(type: .success)
    }
    
}
