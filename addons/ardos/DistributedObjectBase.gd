class_name DistributedObjectBase extends Node

"""
The Distributed Object class is the base class for all network based
(i.e. distributed) objects. These will usually (always?) have a
dclass entry in a *.dc file.
"""

var repository = null
var dclass: GDDCClass = null
var do_id: int = 0
var parent_id: int = 0
var zone_id: int = 0


var __generated: bool = false


## First generate (not from cache).
func generate_init():
	pass

## Inheritors should put functions that require self.zoneId or
## other networked info in this function.
func generate():
	pass

## Called after the object has been generated and all
## of its required fields filled in. Overwrite when needed.
func announce_generate():
	self.__generated = true
