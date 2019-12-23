--Update this list when adding files
local component_post = {
    --example:
    --"container",
	"groundpounder",
	"propagator",
	"burnable",
	--"quaker",
}

local prefab_post = {
    "toadstool_cap",
    "yellowamulet",
    "trap_teeth",
    "cave",
	"beequeen",
	"deerclops",
	"spiderqueen",
	"bearger",
	"cave_entrance_open",
	"catcoon",
	"icehound",
	"firehound",
	"walrus",
	"forest",
	"leif",
	"world",
	"antlion",
	"minifan",
	"spider",
	"spiderqueen",
	"hound",
	"penguin",
	"ash",
}

local stategraph_post = {
    --example:
    --"wilson",
	"deerclops",
	"wilson",
}

local class_post = {
    --example:
    --"components/inventoryitem_replica",
    --"screens/playerhud",
	"widgets/itemtile",
	"widgets/hoverer",
	"widgets/moisturemeter",
	"widgets/controls",
}

local brain_post = {
    --example:
    --"hound",
	"werepig",
	"walrus",
}

modimport("postinit/sim")
modimport("postinit/any")
modimport("postinit/player")

for _,v in pairs(component_post) do
    modimport("postinit/components/"..v)
end

for _,v in pairs(prefab_post) do
    modimport("postinit/prefabs/"..v)
end

for _,v in pairs(stategraph_post) do
    modimport("postinit/stategraphs/SG"..v)
end

for _,v in pairs(brain_post) do
    modimport("postinit/brains/"..v.."brain")
end

for _,v in pairs(class_post) do
    --These contain a path already, e.g. v= "widgets/inventorybar"
    modimport("postinit/".. v)
end