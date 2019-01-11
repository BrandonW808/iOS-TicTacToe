//
//  DrawView.swift
//  IOSTouch
//
//  Created by Brandon Ward on 2018-03-21.
//  Copyright © 2018 Brandon Ward. All rights reserved.
//

import Foundation
import UIKit

class DrawView: UIView {
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var currentLineColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBOutlet var score1: UILabel!
    @IBOutlet var score2: UILabel!
    @IBOutlet var tie: UILabel!
    
    @IBOutlet var Xbutton: UIButton!
    @IBOutlet var Obutton: UIButton!
    
    var currentLines = [NSValue:Line]() //dictionary of key-value pairs
    var finishedLines = [Line]();
    var horizontalLines = [Line]();
    var winningLine = [Line]();
    var verticalLines = [Line]();
    var grid = [CGPoint]();
    var occupied = ["_", "_", "_", "_", "_", "_", "_", "_", "_"];
    var p1Score = 0;
    var p2Score = 0;
    
    var player1 = [Int:[Line]]();
    var player2 = [Int:UIBezierPath]();
    var p1Count = 0;
    var p2Count = 0;
    
    @IBAction func XButton(sender: UIButton){
        Xbutton.isHidden = true;
        Obutton.isHidden = true;
        player = true;
        startOnO = false;
    }
    
    @IBAction func OButton(sender: UIButton){
        Xbutton.isHidden = true;
        Obutton.isHidden = true;
        isComplete = true;
        player = false;
        startOnO = true;
    }
    
    var selectedLineIndex: Int?
    
    var player = true;
    var boardDrawn = false;
    var lineDrawn = false;
    var isComplete = false;
    var isOver = false;
    var startOnO = false;
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder);
        let doubleTapRecognizer =
            UITapGestureRecognizer(target: self,
                                   action: #selector(DrawView.doubleTap(_:)))
        let singleTapRecognizer =
            UITapGestureRecognizer(target: self,
                                   action: #selector(DrawView.tap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.require(toFail: doubleTapRecognizer)
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        singleTapRecognizer.numberOfTapsRequired = 1
        singleTapRecognizer.delaysTouchesBegan = true
        singleTapRecognizer.require(toFail: singleTapRecognizer)
        addGestureRecognizer(singleTapRecognizer)
    }
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer){
        if (selectedLineIndex == nil){
            if (isOver){
                selectedLineIndex = nil //<======================
                currentLines.removeAll();
                finishedLines.removeAll();
                horizontalLines.removeAll();
                verticalLines.removeAll();
                boardDrawn = false;
                p1Count = 0;
                player1.removeAll();
                p2Count = 0;
                player2.removeAll();
                lineDrawn = false;
                isComplete = false;
                winningLine = [];
                isOver = false;
                occupied = ["_", "_", "_", "_", "_", "_", "_", "_", "_"];
                tie.isHidden = true;
            }
        }else if (!boardDrawn){
            finishedLines.remove(at: selectedLineIndex!)
            horizontalLines.removeAll();
            verticalLines.removeAll();
            boardDrawn = false;
            selectedLineIndex = nil;
        }
        setNeedsDisplay()
    }
    
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer){
        let tapPoint = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLineNearPoint(point: tapPoint)
        setNeedsDisplay()
    }
    
    func distanceBetween(from: CGPoint, to: CGPoint) -> CFloat{
        let distXsquared = Float((to.x-from.x)*(to.x-from.x))
        let distYsquared = Float((to.y-from.y)*(to.y-from.y))
        return sqrt(distXsquared + distYsquared);
    }
    
    func indexOfLineNearPoint(point: CGPoint) -> Int? {
        let tolerence: Float = 1.0 //experiment with this value
        for(index,line) in finishedLines.enumerated(){
            let begin = line.begin
            let end = line.end
            let lineLength = distanceBetween(from: begin, to: end)
            let beginToTapDistance = distanceBetween(from: begin, to: point)
            let endToTapDistance = distanceBetween(from: end, to: point)
            if (beginToTapDistance + endToTapDistance - lineLength) < tolerence {
                return index
            }
        }
        return nil
    }

    
    func strokeLine(line: Line){
        //Use BezierPath to draw lines
        let path = UIBezierPath();
        path.lineWidth = lineThickness;
        path.lineCapStyle = CGLineCap.round;
        path.move(to: line.begin);
        path.addLine(to: line.end);
        path.stroke(); //actually draw the path
    }
    
    override func draw(_ rect: CGRect) {
        for line in winningLine {
            if (player){
                UIColor.blue.setStroke()
                strokeLine(line: line)
            }else{
                UIColor.red.setStroke()
                strokeLine(line: line)
            }
        }
        
        finishedLineColor.setStroke() //finished lines in black
        for line in finishedLines{
            strokeLine(line: line);
        }
        
        for (_,line) in currentLines{
            currentLineColor.setStroke()
            strokeLine(line: line)
        }
        for (_,lineArray) in player1{
            for (line) in lineArray{
                UIColor.red.setStroke()
                strokeLine(line: line)
            }
        }
        for (_,path) in player2{
            UIColor.blue.setStroke()
            path.lineWidth = lineThickness;
            path.lineCapStyle = CGLineCap.round;
            path.stroke();
        }
        
        //over-draw the selected line
        if let index = selectedLineIndex {
            UIColor.yellow.setStroke()
            let selectedLine = finishedLines[index]
            strokeLine(line: selectedLine)
        }

    }
    
    //Override Touch Functions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (Obutton.isHidden == true){
            if (!boardDrawn){
                    for touch in touches {
                    let location = touch.location(in: self)
                    let newLine = Line(begin: location, end: location)
                    let key = NSValue(nonretainedObject: touch)
                    currentLines[key] = newLine
                }
            }else if(player && !isOver){
                if (!lineDrawn){
                    let touch = touches.first!;
                    let location = touch.location(in: self);
                    let newLine = Line(begin: location, end: location);
                    var temp = [Line]();
                    temp.append(newLine);
                    player1[p1Count] = temp;
                }else{
                    let touch = touches.first!;
                    let location = touch.location(in: self);
                    let newLine = Line(begin: location, end: location);
                    if (player1[p1Count] != nil){
                        var temp = [Line]();
                        temp = player1[p1Count]!;
                        temp.append(newLine);
                        player1[p1Count] = temp;
                        print("Player 1: ", player1[p1Count]!);
                    }
                }
            }else if (!isOver){
                let touch = touches.first!;
                let temp = UIBezierPath();
                temp.move(to: touch.location(in: self));
                player2[p2Count] = temp;
            }
            
            setNeedsDisplay(); //this view needs to be updated
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (Obutton.isHidden == true){
            for touch in touches {
                if (!boardDrawn){
                    let location = touch.location(in: self)
                    currentLines[NSValue(nonretainedObject: touch)]!.end = location
                }else if(player && !isOver){
                    if (!lineDrawn){
                        let location = touch.location(in: self)
                        player1[p1Count]?[0].end = location
                    }else{
                        let location = touch.location(in: self)
                        if (player1[p1Count] != nil){
                            player1[p1Count]![1].end = location
                        }
                    }
                }else if (!isOver){
                    let temp = player2[p2Count]!;
                    temp.addLine(to: touch.location(in: self));
                    player2[p2Count] = temp;
                }
            }
            setNeedsDisplay(); //this view needs to be updated
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (Obutton.isHidden == true){
            for touch in touches {

                if (!boardDrawn){
                    let location = touch.location(in: self)
                    currentLines[NSValue(nonretainedObject: touch)]!.end = location
                    finishedLines.append(currentLines[NSValue(nonretainedObject: touch)]!);
                    currentLines.removeValue(forKey: NSValue(nonretainedObject: touch));
                }else if(player && !isOver){
                    if (!lineDrawn){
                        let location = touch.location(in: self);
                        player1[p1Count]?[0].end = location;
                        lineDrawn = true;
                        isComplete = false;
                    }else{
                        let location = touch.location(in: self);
                        if (player1[p1Count] != nil){
                            player1[p1Count]![1].end = location;
                            p1Count += 1;
                            player = false;
                            lineDrawn = false;
                            isComplete = true;
                        }
                    }
                }else if (!isOver){
                    let temp = player2[p2Count]!;
                    temp.addLine(to: touch.location(in: self));
                    player2[p2Count] = temp;
                    player = true;
                    p2Count += 1;
                }
            }
            
            if (finishedLines.count == 4){
                boardDrawn = true;

                for line in finishedLines{
                    if (abs(line.begin.x-line.end.x) >= abs(line.begin.y - line.end.y)){
                        horizontalLines.append(line);
                    }else{
                        verticalLines.append(line);
                    }
                }
                if (verticalLines[0].begin.x > verticalLines[1].begin.x) {
                    let temp = verticalLines[0];
                    verticalLines[0] = verticalLines[1];
                    verticalLines[1] = temp;
                }
                if (horizontalLines[0].begin.y > horizontalLines[1].begin.y) {
                    let temp = horizontalLines[0];
                    horizontalLines[0] = horizontalLines[1];
                    horizontalLines[1] = temp;
                }
                
                
                //Check the left side horizontals
                if (horizontalLines[0].begin.x <= horizontalLines[0].end.x){
                    if (verticalLines[0].begin.y <= verticalLines[0].end.y){
                        if (horizontalLines[0].begin.x >= verticalLines[0].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[0].begin.y >= verticalLines[0].end.y){
                        if (horizontalLines[0].begin.x >= verticalLines[0].end.x){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (verticalLines[0].begin.y <= verticalLines[0].end.y){
                        if (horizontalLines[0].end.x >= verticalLines[0].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[0].begin.y >= verticalLines[0].end.y){
                        if (horizontalLines[0].end.x >= verticalLines[0].end.x){
                            boardDrawn = false;
                        }
                    }
                }
                
                if (horizontalLines[1].begin.x <= horizontalLines[1].end.x){
                    if (verticalLines[0].begin.y <= verticalLines[0].end.y){
                        if (horizontalLines[1].begin.x >= verticalLines[0].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[0].begin.y >= verticalLines[0].end.y){
                        if (horizontalLines[1].begin.x >= verticalLines[0].end.x){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (verticalLines[0].begin.y <= verticalLines[0].end.y){
                        if (horizontalLines[1].end.x >= verticalLines[0].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[0].begin.y >= verticalLines[0].end.y){
                        if (horizontalLines[1].end.x >= verticalLines[0].end.x){
                            boardDrawn = false;
                        }
                    }
                }
                
                
                
                //Check the right side horizontals
                if (horizontalLines[0].begin.x >= horizontalLines[0].end.x){
                    if (verticalLines[1].begin.y <= verticalLines[1].end.y){
                        if (horizontalLines[0].begin.x <= verticalLines[0].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[1].begin.y >= verticalLines[1].end.y){
                        if (horizontalLines[0].begin.x <= verticalLines[1].end.x){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (verticalLines[1].begin.y <= verticalLines[1].end.y){
                        if (horizontalLines[0].end.x <= verticalLines[1].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[1].begin.y >= verticalLines[1].end.y){
                        if (horizontalLines[0].end.x <= verticalLines[1].end.x){
                            boardDrawn = false;
                        }
                    }
                }
                
                if (horizontalLines[1].begin.x >= horizontalLines[1].end.x){
                    if (verticalLines[1].begin.y <= verticalLines[1].end.y){
                        if (horizontalLines[1].begin.x <= verticalLines[1].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[1].begin.y >= verticalLines[1].end.y){
                        if (horizontalLines[1].begin.x <= verticalLines[1].end.x){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (verticalLines[1].begin.y <= verticalLines[1].end.y){
                        if (horizontalLines[1].end.x <= verticalLines[1].begin.x){
                            boardDrawn = false;
                        }
                    }else if (verticalLines[1].begin.y >= verticalLines[1].end.y){
                        if (horizontalLines[1].end.x <= verticalLines[1].end.x){
                            boardDrawn = false;
                        }
                    }
                }
                
                
                
                //Check the top verticals
                if (verticalLines[0].begin.y <= verticalLines[0].end.y){
                    if (horizontalLines[0].begin.x <= horizontalLines[0].end.x){
                        if (verticalLines[0].begin.y >= horizontalLines[0].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[0].begin.x >= horizontalLines[0].end.x){
                        if (verticalLines[0].begin.y >= horizontalLines[0].end.y){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (horizontalLines[0].begin.x <= horizontalLines[0].end.x){
                        if (verticalLines[0].end.y >= horizontalLines[0].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[0].begin.x >= horizontalLines[0].end.x){
                        if (verticalLines[0].end.y >= horizontalLines[0].end.y){
                            boardDrawn = false;
                        }
                    }
                }
                
                if (verticalLines[1].begin.y <= verticalLines[1].end.y){
                    if (horizontalLines[0].begin.x >= horizontalLines[0].end.x){
                        if (verticalLines[1].begin.y >= horizontalLines[0].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[0].begin.x <= horizontalLines[0].end.x){
                        if (verticalLines[1].begin.y >= horizontalLines[0].end.y){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (horizontalLines[0].begin.x >= horizontalLines[0].end.x){
                        if (verticalLines[1].end.y >= horizontalLines[0].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[0].begin.x <= horizontalLines[0].end.x){
                        if (verticalLines[1].end.y >= horizontalLines[0].end.y){
                            boardDrawn = false;
                        }
                    }
                }
                
                
                //Check the bottom verticals
                if (verticalLines[0].begin.y >= verticalLines[0].end.y){
                    if (horizontalLines[1].begin.x <= horizontalLines[1].end.x){
                        if (verticalLines[0].begin.y <= horizontalLines[1].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[1].begin.x >= horizontalLines[1].end.x){
                        if (verticalLines[0].begin.y <= horizontalLines[1].end.y){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (horizontalLines[1].begin.x <= horizontalLines[1].end.x){
                        if (verticalLines[0].end.y <= horizontalLines[1].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[1].begin.x >= horizontalLines[1].end.x){
                        if (verticalLines[0].end.y <= horizontalLines[1].end.y){
                            boardDrawn = false;
                        }
                    }
                }
                
                if (verticalLines[1].begin.y >= verticalLines[1].end.y){
                    if (horizontalLines[1].begin.x >= horizontalLines[1].end.x){
                        if (verticalLines[1].begin.y <= horizontalLines[1].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[1].begin.x <= horizontalLines[1].end.x){
                        if (verticalLines[1].begin.y <= horizontalLines[1].end.y){
                            boardDrawn = false;
                        }
                    }
                }else{
                    if (horizontalLines[1].begin.x >= horizontalLines[1].end.x){
                        if (verticalLines[1].end.y <= horizontalLines[1].begin.y){
                            boardDrawn = false;
                        }
                    }else if (horizontalLines[1].begin.x <= horizontalLines[1].end.x){
                        if (verticalLines[1].end.y <= horizontalLines[1].end.y){
                            boardDrawn = false;
                        }
                    }
                }
                
                print("");
                print(occupied[0], "|", occupied[3], "|", occupied[6])
                print(occupied[1], "|", occupied[4], "|", occupied[7]);
                print(occupied[2], "|", occupied[5], "|", occupied[8]);
                
            }else if (finishedLines.count > 4){
                finishedLines.removeAll()
                boardDrawn = false;
            }
            
            if(!player && boardDrawn && !isOver){
                if (isComplete && boardDrawn && !startOnO){
                    //TO DO: Check if is X and is in a valid location
                    var isValid = true;
                    if (player1[p1Count-1]![0].begin.x < player1[p1Count-1]![0].end.x){
                        if (player1[p1Count-1]![0].begin.y < player1[p1Count-1]![0].end.y){
                            if (player1[p1Count-1]![1].begin.y < player1[p1Count-1]![1].end.y){
                                isValid = false;
                            }
                        }else{
                            if (player1[p1Count-1]![1].begin.y > player1[p1Count-1]![1].end.y){
                                isValid = false;
                            }
                        }
                    }else if (!isOver){
                        if (player1[p1Count-1]![0].begin.y < player1[p1Count-1]![0].end.y){
                            if (player1[p1Count-1]![1].begin.y < player1[p1Count-1]![1].end.y){
                                isValid = false;
                            }
                        }else{
                            if (player1[p1Count-1]![1].begin.y > player1[p1Count-1]![1].end.y){
                                isValid = false;
                            }
                        }
                    }
                    if (!isValid){
                        p1Count -= 1;
                        player1.removeValue(forKey: p1Count);
                        player = true;
                        isComplete = false;
                    }else if (!isOver){
                        checkBounds();
                    }
                    setNeedsDisplay()
                }
            }else if (p2Count > 0 && !isOver){
                startOnO = false;
                checkBounds();
            }
            
            if (!boardDrawn && finishedLines.count == 4){
                finishedLines.removeAll();
                horizontalLines.removeAll();
                verticalLines.removeAll();
            }else if (boardDrawn){
                makeGrid()
            }
        
            setNeedsDisplay(); //this view needs to be updated
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        //TODO
    }
    
    func checkBounds(){
        if (!player){
            if (isComplete){
                var isValid = true;
                for i in 0...3{
                    if ((player1[p1Count-1]![0].begin.x < grid[i].x && player1[p1Count-1]![0].end.x > grid[i].x) ||
                        (player1[p1Count-1]![1].begin.x < grid[i].x && player1[p1Count-1]![1].end.x > grid[i].x) ||
                        (player1[p1Count-1]![0].begin.x > grid[i].x && player1[p1Count-1]![0].end.x < grid[i].x) ||
                        (player1[p1Count-1]![1].begin.x > grid[i].x && player1[p1Count-1]![1].end.x < grid[i].x)){
                        isValid = false;
                    }
                    
                    if ((player1[p1Count-1]![0].begin.y < grid[i].y && player1[p1Count-1]![0].end.y > grid[i].y) ||
                        (player1[p1Count-1]![1].begin.y < grid[i].y && player1[p1Count-1]![1].end.y > grid[i].y) ||
                        (player1[p1Count-1]![0].begin.y > grid[i].y && player1[p1Count-1]![0].end.y < grid[i].y) ||
                        (player1[p1Count-1]![1].begin.y > grid[i].y && player1[p1Count-1]![1].end.y < grid[i].y)){
                        isValid = false;
                    }
                }
                if (!isValid){
                    p1Count -= 1;
                    player1.removeValue(forKey: p1Count);
                    player = true;
                }else{
                    checkOccupied();
                }
            }
        }else{
            var isValid = true;
            let cgpath = player2[p2Count-1]!.cgPath;
            for i in 0...3{
                if ((cgpath.boundingBox.maxX > grid[i].x && cgpath.boundingBox.minX < grid[i].x) ||
                    (cgpath.boundingBox.maxY > grid[i].y && cgpath.boundingBox.minY < grid[i].y))
                    {
                        isValid = false;
                }
            }
            if (!isValid){
                p2Count -= 1;
                player2.removeValue(forKey: p2Count);
                player = false;
            }else{
                checkOccupied();
            }
        }
    }
    
    func checkOccupied(){
        var isValid = true;
        if (!player && boardDrawn){
            if (isComplete){
                if (player1[p1Count-1]![0].begin.x < grid[0].x){
                    if (player1[p1Count-1]![0].begin.y < grid[0].y){
                        if (occupied[0] == "_"){
                            occupied[0] = "X";
                        }else{
                            isValid = false;
                        }
                    }else if (player1[p1Count-1]![0].begin.y > grid[0].y && player1[p1Count-1]![0].begin.y < grid[2].y){
                        if (occupied[1] == "_"){
                            occupied[1] = "X";
                        }else{
                            isValid = false;
                        }
                    }else{
                        if (occupied[2] == "_"){
                            occupied[2] = "X";
                        }else{
                            isValid = false;
                        }
                    }
                }else if (player1[p1Count-1]![0].begin.x > grid[0].x && player1[p1Count-1]![0].begin.x < grid[1].x){
                    if (player1[p1Count-1]![0].begin.y < grid[0].y){
                        if (occupied[3] == "_"){
                            occupied[3] = "X";
                        }else{
                            isValid = false;
                        }
                    }else if (player1[p1Count-1]![0].begin.y > grid[0].y && player1[p1Count-1]![0].begin.y < grid[2].y){
                        if (occupied[4] == "_"){
                            occupied[4] = "X";
                        }else{
                            isValid = false;
                        }
                    }else{
                        if (occupied[5] == "_"){
                            occupied[5] = "X";
                        }else{
                            isValid = false;
                        }
                    }
                }else{
                    if (player1[p1Count-1]![0].begin.y < grid[0].y){
                        if (occupied[6] == "_"){
                            occupied[6] = "X";
                        }else{
                            isValid = false;
                        }
                    }else if (player1[p1Count-1]![0].begin.y > grid[0].y && player1[p1Count-1]![0].begin.y < grid[2].y){
                        if (occupied[7] == "_"){
                            occupied[7] = "X";
                        }else{
                            isValid = false;
                        }
                    }else{
                        if (occupied[8] == "_"){
                            occupied[8] = "X";
                        }else{
                            isValid = false;
                        }
                    }
                }
                if (!isValid){
                    p1Count -= 1;
                    player1.removeValue(forKey: p1Count);
                    player = true;
                    isComplete = false;
                }
            }
            }else if (player && boardDrawn && isComplete){
                let path = player2[p2Count-1]!.cgPath;
                if ((path.boundingBox.maxX) < grid[0].x){
                    if ((path.boundingBox.maxY) < grid[0].y){
                        if (occupied[0] == "_"){
                            occupied[0] = "O";
                        }else{
                            print("FUCK")
                            isValid = false;
                        }
                    }else if ((path.boundingBox.maxY) > grid[0].y && (path.boundingBox.maxY) < grid[2].y){
                        if (occupied[1] == "_"){
                            occupied[1] = "O";
                        }else{
                            isValid = false;
                        }
                    }else{
                        if (occupied[2] == "_"){
                            occupied[2] = "O";
                        }else{
                            isValid = false;
                        }
                    }
                }else if ((path.boundingBox.maxX) > grid[0].x && (path.boundingBox.maxX) < grid[1].x){
                    if ((path.boundingBox.maxY) < grid[0].y){
                        if (occupied[3] == "_"){
                            occupied[3] = "O";
                        }else{
                            isValid = false;
                        }
                    }else if ((path.boundingBox.maxY) > grid[0].y && (path.boundingBox.maxY) < grid[2].y){
                        if (occupied[4] == "_"){
                            occupied[4] = "O";
                        }else{
                            isValid = false;
                        }
                    }else{
                        if (occupied[5] == "_"){
                            occupied[5] = "O";
                        }else{
                            isValid = false;
                        }
                    }
                }else{
                    if ((path.boundingBox.maxY) < grid[0].y){
                        if (occupied[6] == "_"){
                            occupied[6] = "O";
                        }else{
                            isValid = false;
                        }
                    }else if ((path.boundingBox.maxY) > grid[0].y && (path.boundingBox.maxY) < grid[2].y){
                        if (occupied[7] == "_"){
                            occupied[7] = "O";
                        }else{
                            isValid = false;
                        }
                    }else{
                        if (occupied[8] == "_"){
                            occupied[8] = "O";
                        }else{
                            isValid = false;
                        }
                    }
                }
                if (!isValid){
                    p2Count -= 1;
                    player2.removeValue(forKey: p2Count);
                    player = false;
                }
        }
        print("");
        print(occupied[0], "|", occupied[3], "|", occupied[6])
        print(occupied[1], "|", occupied[4], "|", occupied[7]);
        print(occupied[2], "|", occupied[5], "|", occupied[8]);
        checkWin();
    }
    
    func checkWin(){
        if (occupied[0] == "X" && occupied[1] == "X" && occupied[2] == "X"){
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y-50)),end: CGPoint(x:(grid[2].x-50),y:grid[2].y+50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[0] == "O" && occupied[1] == "O" && occupied[2] == "O"){
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y-50)),end: CGPoint(x:(grid[2].x-50),y:grid[2].y+50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[3] == "X" && occupied[4] == "X" && occupied[5] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x+((grid[1].x-grid[0].x)/2)),y:(grid[0].y-50)),end: CGPoint(x:(grid[2].x+((grid[1].x-grid[2].x)/2)),y:grid[2].y+50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[3] == "O" && occupied[4] == "O" && occupied[5] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x+((grid[1].x-grid[0].x)/2)),y:(grid[0].y-50)),end: CGPoint(x:(grid[2].x+((grid[1].x-grid[2].x)/2)),y:grid[2].y+50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[6] == "X" && occupied[7] == "X" && occupied[8] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[1].x+50),y:(grid[1].y-50)),end: CGPoint(x:(grid[3].x+50),y:grid[3].y+50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[6] == "O" && occupied[7] == "O" && occupied[8] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[1].x+50),y:(grid[1].y-50)),end: CGPoint(x:(grid[3].x+50),y:grid[3].y+50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[0] == "X" && occupied[3] == "X" && occupied[6] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y-50)),end: CGPoint(x:(grid[1].x+50),y:grid[1].y-50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[0] == "O" && occupied[3] == "O" && occupied[6] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y-50)),end: CGPoint(x:(grid[1].x+50),y:grid[1].y-50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[1] == "X" && occupied[4] == "X" && occupied[7] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y+((grid[2].y-grid[0].y)/2))),end: CGPoint(x:(grid[1].x+50),y:(grid[1].y+((grid[3].y-grid[1].y)/2))));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[1] == "O" && occupied[4] == "O" && occupied[7] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y+((grid[2].y-grid[0].y)/2))),end: CGPoint(x:(grid[1].x+50),y:(grid[1].y+((grid[3].y-grid[1].y)/2))));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[2] == "X" && occupied[5] == "X" && occupied[8] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[2].x-50),y:(grid[2].y+50)),end: CGPoint(x:(grid[3].x+50),y:grid[3].y+50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[2] == "O" && occupied[5] == "O" && occupied[8] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[2].x-50),y:(grid[2].y+50)),end: CGPoint(x:(grid[3].x+50),y:grid[3].y+50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[0] == "X" && occupied[4] == "X" && occupied[8] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y-50)),end: CGPoint(x:(grid[3].x+50),y:grid[3].y+50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[0] == "O" && occupied[4] == "O" && occupied[8] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[0].x-50),y:(grid[0].y-50)),end: CGPoint(x:(grid[3].x+50),y:grid[3].y+50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }else if (occupied[6] == "X" && occupied[4] == "X" && occupied[2] == "X"){
            print("Player 1 Won!")
            let line = Line(begin: CGPoint(x:(grid[1].x+50),y:(grid[1].y-50)),end: CGPoint(x:(grid[2].x-50),y:grid[2].y+50));
            winningLine = [line];
            player = false;
            isOver = true;
            p1Score += 1;
        }else if (occupied[6] == "O" && occupied[4] == "O" && occupied[2] == "O"){
            print("Player 2 Won!")
            let line = Line(begin: CGPoint(x:(grid[1].x+50),y:(grid[1].y-50)),end: CGPoint(x:(grid[2].x-50),y:grid[2].y+50));
            winningLine = [line];
            player = true;
            isOver = true;
            p2Score += 1;
        }
        
        var tied = true;
        for String in occupied{
            if (String == "_"){
                tied = false;
            }
        }
        if (tied == true){
            tie.isHidden = false;
            isOver = true;
        }
        score1.text = "Player 1 Score: \(p1Score)";
        score2.text = "Player 2 Score: \(p2Score)";
        setNeedsDisplay()
    }
    
    func makeGrid(){
        
        for _ in 0...3 {
            let temp = CGPoint.zero;
            grid.append(temp);
        }
        
        //Top left point
        if (horizontalLines[0].begin.x <= horizontalLines[0].end.x){
            grid[0].y = horizontalLines[0].begin.y;
        }else{
            grid[0].y = horizontalLines[0].end.y;
        }
        
        if (verticalLines[0].begin.y <= verticalLines[0].end.y){
            grid[0].x = verticalLines[0].begin.x;
        }else{
            grid[0].x = verticalLines[0].end.x;
        }
        
        //Top right point
        if (horizontalLines[0].begin.x >= horizontalLines[0].end.x){
            grid[1].y = horizontalLines[0].begin.y;
        }else{
            grid[1].y = horizontalLines[0].end.y;
        }
        
        if (verticalLines[1].begin.y <= verticalLines[1].end.y){
            grid[1].x = verticalLines[1].begin.x;
        }else{
            grid[1].x = verticalLines[1].end.x;
        }
        
        //Bottom left point
        if (horizontalLines[1].begin.x <= horizontalLines[1].end.x){
            grid[2].y = horizontalLines[1].begin.y;
        }else{
            grid[2].y = horizontalLines[1].end.y;
        }
        
        if (verticalLines[0].begin.y >= verticalLines[0].end.y){
            grid[2].x = verticalLines[0].begin.x;
        }else{
            grid[2].x = verticalLines[0].end.x;
        }
        
        //Bottom right point
        if (horizontalLines[1].begin.x >= horizontalLines[1].end.x){
            grid[3].y = horizontalLines[1].begin.y;
        }else{
            grid[3].y = horizontalLines[1].end.y;
        }
        
        if (verticalLines[1].begin.y >= verticalLines[1].end.y){
            grid[3].x = verticalLines[1].begin.x;
        }else{
            grid[3].x = verticalLines[1].end.x;
        }
        
    }
}
