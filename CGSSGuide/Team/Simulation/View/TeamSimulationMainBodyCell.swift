//
//  TeamSimulationMainBodyCell.swift
//  CGSSGuide
//
//  Created by zzk on 2017/5/16.
//  Copyright © 2017年 zzk. All rights reserved.
//

import UIKit
import SnapKit

protocol TeamSimulationMainBodyCellDelegate: class {
    func startCalculate(_ teamSimulationMainBodyCell: TeamSimulationMainBodyCell)
    func startSimulate(_ teamSimulationMainBodyCell: TeamSimulationMainBodyCell)
    func cancelSimulating(_ teamSimulationMainBodyCell: TeamSimulationMainBodyCell)
}

class TeamSimulationMainBodyCell: UITableViewCell {
    
    var calculationButton: UIButton!
    
    var calculationGrid: GridLabel!
    
    var simulationButton: UIButton!
    
    var cancelButton: UIButton!
    
    var simulationGrid: GridLabel!
    
    var simulatingIndicator: UIActivityIndicatorView!
    
//    var scoreDistributionButton: UIButton!
//    
//    var scoreDetailButton: UIButton!
//    
//    var supportSkillDetailButton: UIButton!
    
    weak var delegate: TeamSimulationMainBodyCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        calculationButton = UIButton()
        calculationButton.setTitle(NSLocalizedString("一般计算", comment: "队伍详情页面"), for: .normal)
        calculationButton.backgroundColor = Color.dance
        calculationButton.addTarget(self, action: #selector(startCalculate), for: .touchUpInside)
        
        contentView.addSubview(calculationButton)
        calculationButton.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.height.equalTo(30)
            make.top.equalTo(10)
        }
        
        calculationGrid = GridLabel.init(rows: 2, columns: 4)
        contentView.addSubview(calculationGrid)
        calculationGrid.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(calculationButton.snp.bottom).offset(10)
        }
        
        simulationButton = UIButton()
        simulationButton.setTitle(NSLocalizedString("模拟计算", comment: "队伍详情页面"), for: .normal)
        simulationButton.backgroundColor = Color.vocal
        simulationButton.addTarget(self, action: #selector(startSimulate), for: .touchUpInside)
        contentView.addSubview(simulationButton)
        simulationButton.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.height.equalTo(30)
            make.top.equalTo(calculationGrid.snp.bottom).offset(10)
        }
        
        simulatingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        simulationButton.addSubview(simulatingIndicator)
        simulatingIndicator.snp.makeConstraints { (make) in
            make.right.equalTo(simulationButton.titleLabel!.snp.left)
            make.centerY.equalTo(simulationButton)
        }
        
        cancelButton = UIButton()
        cancelButton.setTitle(NSLocalizedString("取消", comment: ""), for: .normal)
        cancelButton.backgroundColor = Color.vocal
        cancelButton.addTarget(self, action: #selector(cancelSimulating), for: .touchUpInside)
        contentView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.right.equalTo(-10)
            make.height.equalTo(30)
            make.top.equalTo(simulationButton)
            make.width.equalTo(0)
            make.left.equalTo(simulationButton.snp.right)
        }
        cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cancelButton.titleLabel?.baselineAdjustment = .alignCenters
        
        simulationGrid = GridLabel.init(rows: 2, columns: 4)
        contentView.addSubview(simulationGrid)
        simulationGrid.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(simulationButton.snp.bottom).offset(10)
            make.bottom.equalTo(-10)
        }
        
//        scoreDistributionButton = UIButton()
//        scoreDistributionButton.setTitle("  " + NSLocalizedString("得分分布", comment: "") + " >", for: .normal)
//        scoreDistributionButton.backgroundColor = Color.parade
//        scoreDistributionButton.addTarget(self, action: #selector(checkScoreDistribution), for: .touchUpInside)
//        contentView.addSubview(scoreDistributionButton)
//        scoreDistributionButton.snp.makeConstraints { (make) in
//            make.left.equalTo(10)
//            make.right.equalTo(-10)
//            make.height.equalTo(30)
//            make.top.equalTo(simulationGrid.snp.bottom).offset(10)
//        }
//        
//
//        scoreDetailButton = UIButton()
//        scoreDetailButton.setTitle("  " + NSLocalizedString("得分详情", comment: "") + " >", for: .normal)
//        scoreDetailButton.backgroundColor = Color.visual
//        scoreDetailButton.addTarget(self, action: #selector(checkScoreDetail), for: .touchUpInside)
//        contentView.addSubview(scoreDetailButton)
//        scoreDetailButton.snp.makeConstraints { (make) in
//            make.left.equalTo(10)
//            make.right.equalTo(-10)
//            make.height.equalTo(30)
//            make.top.equalTo(scoreDistributionButton.snp.bottom).offset(10)
//        }
//        
//        supportSkillDetailButton = UIButton()
//        supportSkillDetailButton.setTitle("  " + NSLocalizedString("辅助技能详情", comment: "") + " >", for: .normal)
//        supportSkillDetailButton.backgroundColor = Color.life
//        supportSkillDetailButton.addTarget(self, action: #selector(checkSupportSkillDetail), for: .touchUpInside)
//        contentView.addSubview(supportSkillDetailButton)
//        supportSkillDetailButton.snp.makeConstraints { (make) in
//            make.left.equalTo(10)
//            make.right.equalTo(-10)
//            make.height.equalTo(30)
//            make.top.equalTo(scoreDetailButton.snp.bottom).offset(10)
//            make.bottom.equalTo(-10)
//        }
        
        prepareGridViewFields()
        
        selectionStyle = .none

    }
    
    private func prepareGridViewFields() {
        var calculationString = [[String]]()
        calculationString.append([NSLocalizedString("表现值", comment: "队伍详情页面"), NSLocalizedString("极限分数", comment: "队伍详情页面") + "1", NSLocalizedString("极限分数", comment: "队伍详情页面") + "2", NSLocalizedString("平均分数", comment: "队伍详情页面")])
        calculationString.append(["", "", "", ""])
        calculationGrid.setContents(calculationString)
        
        var simulationStrings = [[String]]()
        simulationStrings.append(["1%", "5%", "20%", "50%"])
        simulationStrings.append(["", "", "", ""])
        simulationGrid.setContents(simulationStrings)
    }
    
    func resetCalculationButton() {
        calculationButton.setTitle(NSLocalizedString("一般计算", comment: ""), for: .normal)
        calculationButton.isUserInteractionEnabled = true
    }
    
    func stopSimulationAnimating() {
        simulationButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.cancelButton.snp.updateConstraints({ (update) in
                update.width.equalTo(0)
                update.left.equalTo(self.simulationButton.snp.right)
            })
            self.layoutIfNeeded()
        }
        simulatingIndicator.stopAnimating()
        simulationButton.setTitle(NSLocalizedString("模拟计算", comment: ""), for: .normal)
    }
    
    func startSimulationAnimating() {
        simulatingIndicator.startAnimating()
        UIView.animate(withDuration: 0.25) {
            self.cancelButton.snp.updateConstraints({ (update) in
                update.width.equalTo(floor((Screen.shortSide - 20) / 4))
                update.left.equalTo(self.simulationButton.snp.right).offset(1)
            })
            self.layoutIfNeeded()
        }
        simulationButton.isUserInteractionEnabled = false
    }

    func setupCalculationResult(value1: Int, value2: Int, value3: Int, value4: Int) {
        calculationGrid[1, 0].text = String(value1)
        calculationGrid[1, 1].text = String(value2)
        calculationGrid[1, 2].text = String(value3)
        calculationGrid[1, 3].text = String(value4)
    }
    
    func setupSimulationResult(value1: Int, value2: Int, value3: Int, value4: Int) {
        simulationGrid[1, 0].text = String(value1)
        simulationGrid[1, 1].text = String(value2)
        simulationGrid[1, 2].text = String(value3)
        simulationGrid[1, 3].text = String(value4)
    }
    
    
    func setupAppeal(_ appeal: Int) {
        calculationGrid[1, 0].text = String(appeal)
    }
    
    func clearCalculationGrid() {
        calculationGrid[1, 2].text = ""
        calculationGrid[1, 1].text = ""
        calculationGrid[1, 0].text = ""
        calculationGrid[1, 3].text = ""
    }
    
    func clearSimulationGrid() {
        simulationGrid[1, 0].text = ""
        simulationGrid[1, 1].text = ""
        simulationGrid[1, 2].text = ""
        simulationGrid[1, 3].text = ""
    }
    
    func startCalculate() {
        delegate?.startCalculate(self)
    }
    
    func startSimulate() {
        delegate?.startSimulate(self)
    }
    
    func cancelSimulating() {
        delegate?.cancelSimulating(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
