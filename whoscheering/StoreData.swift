//
//  store-data.swift
//  whoscheering
//
//  Created by Conrad on 5/25/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import Foundation


struct StoreData{
    static let categories = ["NFL","NBA","MLB","NHL","MLS","EPL"]
    
    //add IAP id for each team
    //add COLORS for each team
    //details.category.team.colors
    //details.category.team.name
    //details.category.team.appid
    //simplify categories to be a function return, gather from the details array
    
    static let details = [
        "NFL" : ["Chargers","Broncos","Rams","Patriots", "ETC"],
        "NBA" : ["Bulls","Wizards","Raptors","Lakers", "ETC"],
        "MLB" : ["Padres","Angels","Dodgers","Yankees", "ETC"],
        "NHL" : ["Kings","Hockey","Ducks","Oilers", "ETC"],
        "MLS" : ["Galaxy","ETC"],
        "EPL" : ["Etc"]
    ]
    
}