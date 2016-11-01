-- Chopped Straw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

SpecializationUtil.registerSpecialization('ChoppedStraw', 'ChoppedStraw', g_currentModDirectory .. 'ChoppedStraw.lua');
local choppedStrawSpec = SpecializationUtil.getSpecialization('ChoppedStraw');

ChoppedStraw_Register = {};
local modItem = ModsUtil.findModItemByModName(g_currentModName);
--
ChoppedStraw_Register.initialized = false

function ChoppedStraw_Register:loadMap(name)
	g_currentMission.cs_version = '*** ChoppedStraw v'..((modItem and modItem.version) and modItem.version or "?.?.?");
	g_currentMission.cs_mapPath =  name:match("(.+)%/.+")..'/choppedStraw_SDK/';

	if self.specAdded then return; end;
	logInfo(5,'register specialization');

	local addedTo = {};

	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		if v ~= nil then
			-- has Combine spec -> continue
			local allowInsertion = SpecializationUtil.hasSpecialization(Combine, v.specializations) and not SpecializationUtil.hasSpecialization(FruitPreparer, v.specializations);

			--local customEnvironment;
			if allowInsertion then
				logInfo(1,('    vehicleType %q has Combine spec'):format(v.name));
				if v.name:find('.') then
					customEnvironment = Utils.splitString('.', v.name)[1];
					logInfo(1,('      customEnvironment=%q'):format(customEnvironment));
				end;

				if customEnvironment then
					-- has ChoppedStraw spec -> abort
					if rawget(SpecializationUtil.specializations, customEnvironment .. '.ChoppedStraw') ~= nil or rawget(SpecializationUtil.specializations, customEnvironment .. '.choppedStraw') ~= nil then
						logInfo(1,('      already has spec "ChoppedStraw" -> allowInsertion = false'));
						allowInsertion = false;
					end;
				end;
			end;

			if allowInsertion then
				logInfo(1,('        specialization added to %q'):format(v.name));
				table.insert(v.specializations, choppedStrawSpec);
				addedTo[#addedTo + 1] = v.name;
			end;
		end;
	end;

	if #addedTo > 0 then
		logInfo(5,('specialization added to %s vehicle types'):format(#addedTo));
	end;

	self.specAdded = true;
end;

function ChoppedStraw_Register:update(dt)
	if not ChoppedStraw_Register.initialized then
		ChoppedStraw_Register.initialized = true -- Only initialize ONCE.

		-- If SoilMod-v2.x does not exist then do it "the old way"...
		--if modSoilMod2 == nil then
			ChoppedStraw_Register.old_UpdateDestroyCommonArea = Utils.updateDestroyCommonArea;
			Utils.updateDestroyCommonArea = ChoppedStraw_Register.updateDestroyCommonArea;

		--end;
	end;
end;

function ChoppedStraw_Register.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitGrassDestructionToField)
	ChoppedStraw_Register.old_UpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitGrassDestructionToField);

	-- iterate over strawTypes
	--for _,entry in pairs(g_currentMission.cs_strawTypes) do

		-- This is deprecated since FS15?
		--Utils.updateDensity(entry.foliageId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);

		-- Düngen hier irgendwie einbauen!
		if (g_currentMission.cs_globalFertilization) then
			Utils.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		end;

	--end;
end;

Utils.updateStrawArea = function(choppedStrawFoliageId, x, z, x1, z1, x2, z2)

	local detailId = g_currentMission.terrainDetailId;
	local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(nil, x, z, x1, z1, x2, z2);
	
	setDensityCompareParams(detailId, "greater", 0);
	local density, area, _ = getDensityParallelogram(detailId, x,z, widthX,widthZ, heightX,heightZ, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels);
	setDensityCompareParams(detailId, "greater", -1);
	if area > 0 then
		terrainValue = math.floor(density/area + 0.5);
    end;
	if terrainValue < 5 then
		setDensityMaskedParallelogram(choppedStrawFoliageId, x, z, widthX, widthZ, heightX, heightZ, 0, 1, g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 1)
	end;
end;

function ChoppedStraw_Register:deleteMap() end;
function ChoppedStraw_Register:keyEvent(unicode, sym, modifier, isDown) end;
function ChoppedStraw_Register:mouseEvent(posX, posY, isDown, isUp, button) end;
function ChoppedStraw_Register:draw() end;

addModEventListener(ChoppedStraw_Register);
