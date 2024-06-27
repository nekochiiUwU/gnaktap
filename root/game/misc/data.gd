extends Node

var shop:Dictionary = {
		"AR": {
			"type": "gun", 
			"base": "AR", 
			"stats": {
				"damages": 25,
				"firerate": 10,
				"magsize": 30,
				"stability": 1,
				"dropoff": 10,
				"scope": 1.5
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		}, 
		"cut": {
			"type": "melee", 
			"base": "cut", 
			"stats": {
				"damages": 40,
				"animspeed": 1,
				"size": 1,
				"movespeed": 1,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 2.
		},
		"fire": {
			"type": "spell", 
			"base": "fire", 
			"stats": {
				"damages": 25,
				"cooldown": 3,
				"manacost": 30,
				"speed": 3,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		},
		"water": {
			"type": "spell", 
			"base": "water", 
			"stats": {
				"damages": 40,
				"cooldown": 2,
				"manacost": 40,
				"speed": 4,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		},
		"light": {
			"type": "spell", 
			"base": "light", 
			"stats": {
				"damages": 30,
				"cooldown": 1,
				"manacost": 20,
				"speed": 1,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		},
		"nothing": {
			"type": "nothing", 
			"base": "nothing", 
			"stats": {
				"nothing1":0,
				"nothing2":0,
				"nothing3":0,
				"nothing4":0
				},
			"upgrades":[],
			"state": "idle", 
			"weight": 2.
		}
}
