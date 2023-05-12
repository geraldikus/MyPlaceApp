//
//  RatingControl.swift
//  MyPlaces
//
//  Created by Anton on 21.04.23.
//

import UIKit

@IBDesignable class RatingControl: UIStackView { // @IBDesignable нужно для того, чтобы вы констрейнты и другие графические изменения появились в Main Storyboard
    // MARK: Properties
    
    var rating = 0 {
        didSet {
            updateButtonSelectionStates()
        }
    }
    
    private var ratingButtons = [UIButton]()
    
    @IBInspectable var starWidth: CGFloat = 44.0 {
        didSet {
            setupButtons()
        }
    }

    @IBInspectable var starHeight: CGFloat = 44.0 {
        didSet {
            setupButtons()
        }
    }
    
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    

    // MARK: Intitialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: Button Action
    
    @objc func ratingButtonTapped(button: UIButton) {
        
        guard let index = ratingButtons.firstIndex(of: button) else { return }
        
        // Calculate the rating of the selected button
        
        let selectedRating = index + 1
        
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
    }
    
    // MARK: Private Methods
    
    private func setupButtons() {
        
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        
        // Load button image
        
        let bundle = Bundle(for: type(of: self))
        
        
        let filledStar = UIImage(named: "filledStar",
                                 in: bundle,
                                 compatibleWith: self.traitCollection)
        
        let emptyStar = UIImage(named: "emptyStar",
                                in: bundle,
                                compatibleWith: self.traitCollection)
        
        let highlightedStar = UIImage(named: "highlightedStar",
                                      in: bundle,
                                      compatibleWith: self.traitCollection)
        
        
        
        for _ in 1...starCount {
            
            // create the button
            
            let button = UIButton()
            
            // Set the button image
            
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: .highlighted)
            button.setImage(highlightedStar, for: [.highlighted, .selected])
           
            // Add constraints
            
            button.translatesAutoresizingMaskIntoConstraints = false // отключает автоматически сгенерированные констрейнты для кнопки
            button.heightAnchor.constraint(equalToConstant: starHeight).isActive = true
            button.widthAnchor.constraint(equalToConstant: starWidth).isActive = true
            
            // Setup the button actions
            
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the stack view
            
            addArrangedSubview(button)
            
            // Add the new button on the ratingButtons (Array)
            ratingButtons.append(button)
            
        }
       
        updateButtonSelectionStates()
    }
    
    private func updateButtonSelectionStates() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
