//
//  CategoryController.swift
//  Time
//
//  Created by Soren Nelson on 5/18/17.
//  Copyright © 2017 SORN. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

class CategoryContoller {
    
    static let sharedInstance = CategoryContoller()
    var categories =  [Category]()
    var ref = UserController.sharedInstance.userRef?.child("categories")
    
    /// Creates a new category. Only is called when you are creating a project with a new category.
    ///
    /// - Parameters:
    ///   - name: the name of the category.
    ///   - projectName: the anem of the Project being created
    ///   - weight: the weight of the Project, as a double
    ///   - deadline: the deadline of the project
    func newCategory(name: String?, projectName: String?, weight: Double, deadline: Date?, presetSessionLength: Double?, scheduledDate: Date?) {
        
        var category: Category
        if let name = name {
            
            if let category = self.getCategoryFromRef(ref: name) {
                let project = ProjectController.sharedInstance.newProject(name: projectName, categoryName: name, deadline: deadline, weight: weight, presetSessionLength: presetSessionLength, scheduledDate: scheduledDate)
                newProjectInExistingCategory(category: category, project: project)
                return
                
            } else {
                category = Category.init(name: name)
            }
        } else {
            
            // if Other category already exists
            if let category = self.getCategoryFromRef(ref: "Other") {
                let project = ProjectController.sharedInstance.newProject(name: projectName, categoryName: "Other", deadline: deadline, weight: weight, presetSessionLength: presetSessionLength, scheduledDate: scheduledDate)
                newProjectInExistingCategory(category: category, project: project)
                return
                
            } else {
                category = Category.init(name: "Other")
            }
            
        }
        
        let project = ProjectController.sharedInstance.newProject(name: projectName, categoryName: category.name, deadline: deadline, weight: weight, presetSessionLength: presetSessionLength, scheduledDate: scheduledDate)
        
        category.projects.append(project)
        category.projectRefs.append(project.firebaseRef!.key)
        
        let uid = FIRAuth.auth()?.currentUser?.uid
        category.firebaseRef = UserController.sharedInstance.userRef?.child("categories").childByAutoId()
        
        categories.append(category)
        
        let updateKeys = ["/users/\(uid ?? "UID")/categories/\(category.firebaseRef!.key)": category.toAnyObject() as! [String: Any]]
        FIRDatabase.database().reference().updateChildValues(updateKeys)
    }
    
    /// Add new project to an existing category.
    ///
    /// - Parameters:
    ///   - category: the existing category
    ///   - project: the new project
    func newProjectInExistingCategory(category: Category, project: Project) {
        var cat = category
        cat.projectRefs.append(project.firebaseRef!.key)
        
        var count = 0
        for c in categories {
            if cat.isEqual(rhs: c) {
                break
            }
            count += 1
        }
        categories.remove(at: count)
        categories.append(cat)
        
        let uid = FIRAuth.auth()?.currentUser?.uid
        let updateKeys = ["/users/\(uid ?? "UID")/categories/\(cat.firebaseRef!.key)": cat.toAnyObject() as! [String: Any]]
        FIRDatabase.database().reference().updateChildValues(updateKeys)
        
    }
    
    
    func removeProjectFromCategory(categoryName: String, project: Project) {
        
        var category: Category?
        
        var cIndex = -1
        for c in categories {
            cIndex += 1
            if c.name == categoryName {
                category = c
                break
            }
        }
        
        var index = -1
        for p in (category?.projects)! {
            index += 1
            if p.isEqual(rhs: project) {
                break
            }
        }
        
        category?.projects.remove(at: index)
        category?.projectRefs.remove(at: index)
        
        categories[cIndex] = category!
        
        let uid = FIRAuth.auth()?.currentUser?.uid
        let updateKeys = ["/users/\(uid ?? "UID")/categories/\(category?.firebaseRef!.key ?? "")": category?.toAnyObject() as! [String: Any]]
        FIRDatabase.database().reference().updateChildValues(updateKeys)
    }
    
    
// FIXME: not working
    
    /// Gets the category from the given reference
    ///
    /// - Parameter ref: the categories reference
    /// - Returns: an optional category
    func getCategoryFromRef(ref: String) -> Category? {
        for category in categories {
            if category.name == ref {
                return category
            }
        }
        return nil
    }
    
    
    /// Fetch the projects for a category.
    ///
    /// - Parameters:
    ///   - category: the category to grab the projects for
    ///   - _completion: whether the category was successful and the category with the projects array now filled.
    func fetchProjectsFromCategoryRef(category: Category, _completion:@escaping(_ category:Category?, _ success:Bool) -> Void) {
        
        guard let firebaseRef = category.firebaseRef else { return }
        var cat = category
        
        ref?.child(firebaseRef.key).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            guard let projects = value?["Projects"] as? [String] else { return }

            var count = 0
            for reference in projects {
                count += 1
                FIRDatabase.database().reference().child("projects").child(reference).observeSingleEvent(of: .value, with: { (snapshot) in
                    var project = Project.init(snapshot: snapshot)
                    project.firebaseRef = snapshot.ref
                    cat.projects.append(project)
                    
                    if count == projects.count {
                        _completion(cat, true)
                    }
                })
            }
            
        })
    }
    
}













