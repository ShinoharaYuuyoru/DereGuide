//
//  TeamDetailViewController.swift
//  CGSSGuide
//
//  Created by zzk on 16/7/30.
//  Copyright © 2016年 zzk. All rights reserved.
//

import UIKit

class TeamDetailViewController: UIViewController {
    
    var team: CGSSTeam!
    var teamDV: TeamDetailView!
    var sv: UIScrollView!
    
    //var hud: CGSSLoadingHUD!
    var live: CGSSLive?
    var beatmap: CGSSBeatmap?
    var diff: Int?
    var usingManualValue: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        self.automaticallyAdjustsScrollViewInsets = false
        sv = UIScrollView.init(frame: CGRect(x: 0, y: 64, width: CGSSGlobal.width, height: CGSSGlobal.height - 64))
        teamDV = TeamDetailView.init(frame: CGRect(x: 0, y: 0, width: CGSSGlobal.width, height: 0))
        // teamDV.initWith(team)
        teamDV.delegate = self
        sv.addSubview(teamDV)
        //hud = CGSSLoadingHUD()
        //view.addSubview(hud)
        view.addSubview(sv)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        teamDV.initWith(team)
        sv.contentSize = teamDV.frame.size
    }
    
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

//MARK: TeamEditViewControllerDelegate协议方法
extension TeamDetailViewController: TeamEditViewControllerDelegate {
    func save(_ team: CGSSTeam) {
        CGSSTeamManager.defaultManager.removeATeam(self.team)
        self.team = team
        CGSSTeamManager.defaultManager.addATeam(team)
    }
}

//MARK: TeamDetailViewDelegate 协议方法
extension TeamDetailViewController: TeamDetailViewDelegate {
  
    func advanceCalc() {
        
        func doSimulationBy(simulator: CGSSLiveSimulator, times: UInt) {
            simulator.simulate(times: times, progress: { (a, b) in
                DispatchQueue.main.async { [weak self] in
                    // self.teamDV.advanceProgress.progress = Float(a) / Float(b)
                    self?.teamDV.advanceCalculateButton.setTitle(NSLocalizedString("计算中...", comment: "") + "(\(String.init(format: "%d", a * 100 / b))%)", for: .normal)
                }
            }, callback: { (result) in
                DispatchQueue.main.async { [weak self] in
                    self?.teamDV.updateScoreGridSimulateResulte(result1: result.get(percent: 1), result2: result.get(percent: 5), result3: result.get(percent: 20), result4: result.get(percent: 50))
                    self?.teamDV.resetAdCalcButton()
                    self?.teamDV.advanceProgress.progress = 0
                }
            })
        }
        
        if let live = self.live, let diff = self.diff {
            self.teamDV.clearAdScoreGrid()
            if team.hasUnknownSkills() {
                showUnknownSkillAlert()
            }
            let coordinator = CGSSLiveCoordinator.init(team: team, live: live, simulatorType: teamDV.simulatorType, grooveType: teamDV.grooveType, diff: diff, fixedAppeal: usingManualValue ? team.customAppeal : nil)
            let simulator = coordinator.generateLiveSimulator(options: .init(rawValue: 0))
            DispatchQueue.global(qos: .userInitiated).async {
                #if DEBUG
                    doSimulationBy(simulator: simulator, times: 500)
                #else
                    doSimulationBy(simulator: simulator, times: 10000)
                #endif
            }
        } else {
            showNotSelectSongAlert()
            teamDV.resetAdCalcButton()
        }
    }
    
    func manualFieldBegin() {
        var offset = teamDV.bottomView.fy + teamDV.manualValueTF.fy + teamDV.manualValueTF.fheight - sv.contentOffset.y + 258 - sv.fheight
        offset += UIApplication.shared.statusBarFrame.size.height - 20
        if offset > 0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.sv.contentOffset.y += offset
            })
        }
    }

    func manualFieldDone(_ value: Int) {
        team.customAppeal = value
        CGSSTeamManager.defaultManager.writeToFile(nil)
    }

    
    func usingManualValue(using: Bool) {
        usingManualValue = using
    }

    func skillShowOrHide() {
        UIView.animate(withDuration: 0.25, animations: {
            self.sv.contentSize = self.teamDV.frame.size
        })
    }
    
    func selectSong() {
        let songSelectVC = TeamSongSelectViewController()
        songSelectVC.delegate = self
        navigationController?.pushViewController(songSelectVC, animated: true)
    }
    
    func backFieldDone(_ value: Int) {
        team.supportAppeal = value
        teamDV.updatePresentValueGrid(team)
        CGSSTeamManager.defaultManager.writeToFile(nil)
    }
    
    func backFieldBegin() {
        var offset = teamDV.backSupportTF.fy + teamDV.backSupportTF.fheight - sv.contentOffset.y + 258 - sv.fheight
        offset += UIApplication.shared.statusBarFrame.size.height - 20
        if offset > 0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.sv.contentOffset.y += offset
            })
        }
    }
    
    func editTeam() {
        let teamEditDVC = TeamEditViewController()
        teamEditDVC.delegate = self
        teamEditDVC.initWith(team)
        
        navigationController?.pushViewController(teamEditDVC, animated: true)
        
    }
    
    func showUnknownSkillAlert() {
        let alert = UIAlertController.init(title: NSLocalizedString("提示", comment: ""), message: NSLocalizedString("队伍中存在未知的技能类型，计算结果可能不准确。", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("确定", comment: "弹出框按钮"), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showNotSelectSongAlert() {
        let alert = UIAlertController.init(title: NSLocalizedString("提示", comment: "弹出框标题"), message: NSLocalizedString("请先选择歌曲", comment: "弹出框正文"), preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("确定", comment: "弹出框按钮"), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startCalc() {
        if let live = self.live, let diff = self.diff {
            self.teamDV.clearScoreGrid()
            if team.hasUnknownSkills() {
                showUnknownSkillAlert()
            }
            let coordinator = CGSSLiveCoordinator.init(team: team, live: live, simulatorType: teamDV.simulatorType, grooveType: teamDV.grooveType, diff: diff, fixedAppeal: usingManualValue ? team.customAppeal : nil)
            let simulator1 = coordinator.generateLiveSimulator(options: .perfectTolerence)
            self.teamDV.updateSimulatorPresentValue(coordinator.fixedAppeal ?? coordinator.appeal)
            let simulator2 = coordinator.generateLiveSimulator(options: .init(rawValue: 0))
            
            self.teamDV.updateScoreGrid(value1: coordinator.fixedAppeal ?? coordinator.appeal, value2: simulator1.max, value3: simulator2.max, value4: simulator2.average)
            self.teamDV.resetCalcButton()
        } else {
            showNotSelectSongAlert()
            teamDV.resetCalcButton()
        }
    }
    
    func cardIconClick(_ id: Int) {
        if let card = CGSSDAO.sharedDAO.findCardById(id) {
            let cardDVC = CardDetailViewController()
            cardDVC.card = card
            navigationController?.pushViewController(cardDVC, animated: true)
        }
    }
    func liveTypeButtonClick() {
        let alvc = UIAlertController.init(title: NSLocalizedString("选择歌曲模式", comment: "弹出框标题"), message: nil, preferredStyle: .actionSheet)
        alvc.popoverPresentationController?.sourceView = teamDV.liveTypeButton
        alvc.popoverPresentationController?.sourceRect = CGRect(x: 0, y: teamDV.liveTypeButton.fheight / 2, width: 0, height: 0)
        alvc.popoverPresentationController?.permittedArrowDirections = .right
        for simulatorType in CGSSLiveSimulatorType.getAll() {
            alvc.addAction(UIAlertAction.init(title: simulatorType.toString(), style: .default, handler: { (a) in
                self.teamDV.simulatorType = simulatorType
                if ![.normal, .parade].contains(simulatorType) {
                    self.teamDV.showGrooveSelectButton()
                    if self.teamDV.grooveType == nil {
                        self.teamDV.grooveType = CGSSGrooveType.init(cardType: (self.team.leader.cardRef?.cardType)!)!
                    }
                } else {
                    self.teamDV.grooveType = nil
                    self.teamDV.hideGrooveSelectButton()
                }
                self.sv.contentSize = self.teamDV.frame.size
                }))
        }
        alvc.addAction(UIAlertAction.init(title: NSLocalizedString("取消", comment: "弹出框按钮"), style: .cancel, handler: nil))
        self.present(alvc, animated: true, completion: nil)
    }
    
    func grooveTypeButtonClick() {
        let alvc = UIAlertController.init(title: NSLocalizedString("选择Groove类别", comment: "弹出框标题"), message: nil, preferredStyle: .actionSheet)
        alvc.popoverPresentationController?.sourceView = teamDV.grooveTypeButton
        alvc.popoverPresentationController?.sourceRect = CGRect(x: 0, y: teamDV.grooveTypeButton.fheight / 2, width: 0, height: 0)
        alvc.popoverPresentationController?.permittedArrowDirections = .right
        for grooveType in CGSSGrooveType.getAll() {
            alvc.addAction(UIAlertAction.init(title: grooveType.rawValue, style: .default, handler: { (a) in
                self.teamDV.grooveType = grooveType
                }))
        }
        alvc.addAction(UIAlertAction.init(title: NSLocalizedString("取消", comment: "弹出框按钮"), style: .cancel, handler: nil))
        self.present(alvc, animated: true, completion: nil)
        
    }
    
}

//MARK: BaseSongTableViewControllerDelegate的协议方法
extension TeamDetailViewController: BaseSongTableViewControllerDelegate {
    func selectLive(_ live: CGSSLive, beatmap: CGSSBeatmap, diff: Int) {
        teamDV.updateSongInfo(live, beatmap: beatmap, diff: diff)
        self.live = live
        self.beatmap = beatmap
        self.diff = diff
    }
}
