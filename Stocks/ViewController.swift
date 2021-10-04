//
//  ViewController.swift
//  Stocks
//
//  Created by Dmitriy Maslennikov on 03/10/2021.
//  Copyright © 2021 Dmitriy Maslennikov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double) {
        self.activityIndicator.stopAnimating()
            
        self.symbolLabel.text = symbol
            
        self.companyNameLabel.text = companyName
        
        self.priceLabel.text = "$\(price)"
            
        if String(priceChange).first == "-" {
            self.priceChangeLabel.textColor = .red
            self.priceChangeLabel.text = "\(priceChange)"
        } else {
            self.priceChangeLabel.textColor = .green
            self.priceChangeLabel.text = "+\(priceChange)"
        }
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let symbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
//                self.showAlert("server")
                print("Invalid JSON format")
                return
            }
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName,
                                      symbol: symbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
//            self.showAlert("server")
            print("JSON parsing Error: " + error.localizedDescription)
        }
    }
    
    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?&token=pk_d6375247ffb24c7d939ea255de7a378e")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
//                self.showAlert("server")
                print("Network Error")
                return
            }
            self.parseQuote(data: data)
        }
        dataTask.resume()
    }
    
    private func requestImage(for symbol: String) {
        let url = URL(string: "https://storage.googleapis.com/iex/api/logos/\(symbol).png")!
            
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                DispatchQueue.main.async {
                    let image = UIImage(named: "default")
                    self.companyImage.image = image
                            
                    print("Error getting the image")
                }
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self.companyImage.image = image
            }
        }
        dataTask.resume()
    }
    
    private func requestQuoteUpdate() {
        let image = UIImage(named: "default")
        self.companyImage.image = image
        
        self.activityIndicator.startAnimating()
        
        self.companyNameLabel.text = "-"
        self.symbolLabel.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.text = "-"
        self.priceChangeLabel.textColor = .label
        
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(self.companies.values)[selectedRow]
        
        self.requestQuote(for: selectedSymbol)
        self.requestImage(for: selectedSymbol)
    }
    
    private func parseCompanies(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [[String: Any]]
            else {
                print("Invalid JSON format")
                return
            }
            
            for company in json {
                let companyName: String = company["companyName"] as! String
                let companySymbol: String = company["symbol"] as! String

                self.companies[companyName] = companySymbol
            }
            
            DispatchQueue.main.async {
                self.companyPickerView.reloadComponent(0)
                self.requestQuoteUpdate()
            }
        } catch {
//            self.showAlert("server")
            print("Companies parsing Error: " + error.localizedDescription)
        }
    }
    
    private func requestCompanies() {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/iexvolume?&token=pk_d6375247ffb24c7d939ea255de7a378e")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
//                self.showAlert("network")
                return
            }
            self.parseCompanies(data: data)
        }
        dataTask.resume()
    }
    
    @IBOutlet weak var companyImage: UIImageView!
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var companyPickerView: UIPickerView!
    
    private var companies: [String:String] = [:]
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.startAnimating()
        self.activityIndicator.hidesWhenStopped = true
        
        self.companyNameLabel.textColor = .secondaryLabel
        
        self.companyImage.layer.borderColor = UIColor.secondarySystemFill.cgColor
        self.companyImage.layer.borderWidth = 3
        self.companyImage.layer.cornerRadius = 20
        self.companyImage.backgroundColor = .white

        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        
        self.requestCompanies()
    }

    // MARK: - pickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.activityIndicator.startAnimating()
        
        let selectedSymbol = Array(self.companies.values)[row]
        self.requestQuote(for: selectedSymbol)
        self.requestImage(for: selectedSymbol)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(self.companies.keys)[row]
    }
}
