-- Chopped Straw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

SpecializationUtil.registerSpecialization('ChoppedStraw', 'ChoppedStraw', g_currentModDirectory .. 'ChoppedStraw.lua');
local choppedStrawSpec = SpecializationUtil.getSpecialization('ChoppedStraw');

ChoppedStraw_Register = {};
local modItem = ModsUtil.findModItemByModName(g_currentModName);
ChoppedStraw.version = '*** ChoppedStraw v'..((modItem and modItem.version) and modItem.version or "?.?.?");

--
ChoppedStraw_Register.initialized = false

function ChoppedStraw_Register:loadMap(name)
	g_currentMission.mapPath =  name:match("(.+)%/.+")..'/choppedStraw_SDK/';
	--print(('AddChoppesStraw.lua: loadMap name = %s'):format(g_currentMission.mapPath));

	if self.specAdded then return; end;
	print(('%s register specialization ***'):format(ChoppedStraw.version));

	local addedTo = {};

	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		if v ~= nil then
			-- has Combine spec -> continue
			local allowInsertion = SpecializationUtil.hasSpecialization(Combine, v.specializations) and not SpecializationUtil.hasSpecialization(FruitPreparer, v.specializations);

			--local customEnvironment;
			if allowInsertion then
				-- print(('\tvehicleType %q has Combine spec'):format(v.name));
				if v.name:find('.') then
					customEnvironment = Utils.splitString('.', v.name)[1];
					-- print(('\t\tcustomEnvironment=%q'):format(customEnvironment));
				end;

				if customEnvironment then
					-- has ChoppedStraw spec -> abort
					if rawget(SpecializationUtil.specializations, customEnvironment .. '.ChoppedStraw') ~= nil or rawget(SpecializationUtil.specializations, customEnvironment .. '.choppedStraw') ~= nil then
						-- print(('\t\talready has spec "ChoppedStraw" -> allowInsertion = false'));
						allowInsertion = false;
					end;
				end;
			end;

			if allowInsertion then
				-- print(('\tChoppedStraw spec added to %q'):format(v.name));
				table.insert(v.specializations, choppedStrawSpec);
				addedTo[#addedTo + 1] = v.name;
			end;
		end;
	end;

	if #addedTo > 0 then
		print(('%s specialization added to %s vehicle types ***'):format(ChoppedStraw.version, #addedTo));
		--print('*** ChoppedStraw added to:\n\t\t' .. table.concat(addedTo, '\n\t\t'));
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
	for _,entry in pairs(ChoppedStraw.strawTypes) do

		-- This is deprecated since FS15?
		Utils.updateDensity(entry.foliageId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);

		-- Düngen hier irgendwie einbauen!
		if (ChoppedStraw.globalFertilization and entry.allowFertilization) then
			--Utils.updateSprayArea(float startWorldX, float startWorldZ, float widthWorldX, float widthWorldZ, float heightWorldX, float heightWorldZ)
		end;

	end;
end;

Utils.updateStrawArea = function(choppedStrawFoliageId, x, z, x1, z1, x2, z2)

	local dx, dz, dwidthX, dwidthZ, dheightX, dheightZ = Utils.getXZWidthAndHeight(nil, x, z, x1, z1, x2, z2);
	
	local includeMask = 2^g_currentMission.cultivatorChannel + 2^g_currentMission.sowingChannel + 2^g_currentMission.ploughChannel;
	
	setDensityMaskParams(choppedStrawFoliageId, "greater", 0,0,includeMask,0)
	
	setDensityMaskedParallelogram(choppedStrawFoliageId, dx, dz, dwidthX, dwidthZ, dheightX, dheightZ,	0, 1,	g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,	1)
	
	setDensityMaskParams(choppedStrawFoliageId, "greater", -1)
end;

function ChoppedStraw_Register:deleteMap() end;
function ChoppedStraw_Register:keyEvent(unicode, sym, modifier, isDown) end;
function ChoppedStraw_Register:mouseEvent(posX, posY, isDown, isUp, button) end;
function ChoppedStraw_Register:draw() end;

addModEventListener(ChoppedStraw_Register);
