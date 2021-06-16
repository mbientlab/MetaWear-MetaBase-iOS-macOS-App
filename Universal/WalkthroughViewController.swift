//
//  WalkthroughViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 3/20/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import PNChart
import MetaWear

class WalkthroughViewController: UIViewController {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    var chart: PNLineChart?
    var dataArray = [CGFloat](repeating: 1.0, count: 30)
    let tutorial = Tutorial()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tutorial.delegate = self
        tutorial.startWalkthrough()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard chart == nil else {
            return
        }
        
        let data = PNLineChartData()
        data.color = .white
        data.inflexionPointStyle = .circle
        data.itemCount = UInt(dataArray.count)
        data.getData = {
            PNLineChartDataItem(y: self.dataArray[Int($0)])
        }
        
        chart = PNLineChart(frame: iconImageView.frame)
        chart?.backgroundColor = .clear
        chart?.displayAnimated = false
        chart?.yFixedValueMax = 3.0
        chart?.yFixedValueMin = 0.0
        chart?.showLabel = false
        chart?.showGenYLabels = false
        chart?.showYGridLines = false
        chart?.xLabels = (0..<dataArray.count).map { String($0) }
        chart?.chartData = [data]
        chart?.stroke()
        chart?.isHidden = true
        view.addSubview(chart!)
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        tutorial.buttonTapped()
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        tutorial.skip()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let device = sender as? MetaWear else {
            return
        }
        if let destination = segue.destination as? MainTableViewController {
            destination.savedMetaWears.addDevice(device)
        }
    }
}

extension WalkthroughViewController: TutorialDelegate {
    func updateUI(message: String, icon: UIImage?, buttonText: String?, chart: Bool) {
        DispatchQueue.main.async {
            self.chart?.isHidden = !chart
            if chart {
                self.dataArray = [CGFloat](repeating: 1.0, count: 30)
                self.chart?.stroke()
            }
            UIView.transition(with: self.mainLabel,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.mainLabel.text = message
            })
            UIView.transition(with: self.iconImageView,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.iconImageView.isHidden = icon == nil
                                self?.iconImageView.image = icon
            })
            UIView.transition(with: self.button,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.button.isHidden = buttonText == nil
                                self?.button.setTitle(buttonText, for: .normal)
            })
        }
    }
    
    func tutorialComplete(device: MetaWear?, error: Error?) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "UnwindToHome", sender: error == nil ? device : nil)
        }
    }
    
    func newDataPoint(value: CGFloat) {
        DispatchQueue.main.async {
            self.dataArray.removeFirst()
            self.dataArray.append(value)
            self.chart?.stroke()
        }
    }
}
