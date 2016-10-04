-- Chopped Straw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

SpecializationUtil.registerSpecialization('ChoppedStraw', 'ChoppedStraw', g_currentModDirectory .. 'ChoppedStraw.lua');
local choppedStrawSpec = SpecializationUtil.getSpecialization('ChoppedStraw');

ChoppedStraw_Register = {};
local modItem = ModsUtil.findModItemByModName(g_currentModName);
ChoppedStraw_Register.version = (modItem and modItem.version) and modItem.version or "?.?.?";

--
ChoppedStraw_Register.initialized = false

function ChoppedStraw_Register:loadMap(name)
	if self.specAdded then return; end;

	print('*** ChoppedStraw v'..ChoppedStraw_Register.version..' specialization loading ***');

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

	--if #addedTo > 0 then
	--	print('*** ChoppedStraw added to:\n\t\t' .. table.concat(addedTo, '\n\t\t'));
	--end;

	self.specAdded = true;
end;

function ChoppedStraw_Register:update(dt)
  if not ChoppedStraw_Register.initialized then
    ChoppedStraw_Register.initialized = true -- Only initialize ONCE.

    -- If SoilMod did not "call us", then do it "the old way"...
    --if not ChoppedStraw_Register.soilModPresent then
		ChoppedStraw_Register.old_UpdateDestroyCommonArea = Utils.updateDestroyCommonArea;
		Utils.updateDestroyCommonArea = ChoppedStraw_Register.updateDestroyCommonArea;

		ChoppedStraw_Register.old_updateSowingArea = Utils.updateSowingArea;
		Utils.updateSowingArea = ChoppedStraw_Register.updateSowingArea;
    --end;
  end;
end;

function ChoppedStraw_Register.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitGrassDestructionToField)
	ChoppedStraw_Register.old_UpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitGrassDestructionToField);
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDSTRAW] then
		Utils.updateDensity(g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDSTRAW].preparingOutputId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
	end;
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDMAIZE] then
		Utils.updateDensity(g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDMAIZE].preparingOutputId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
	end;
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDRAPE] then
	Utils.updateDensity(g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDRAPE].preparingOutputId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
	end;
end;

function ChoppedStraw_Register.updateSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, useDirectPlanting)
	local numPixels, numDetailPixels = ChoppedStraw_Register.old_updateSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, useDirectPlanting);
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDSTRAW] then
		Utils.updateDensity(g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDSTRAW].preparingOutputId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
	end;
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDMAIZE] then
		Utils.updateDensity(g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDMAIZE].preparingOutputId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
	end;
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDRAPE] then
		Utils.updateDensity(g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDRAPE].preparingOutputId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
	end;

	return numPixels, numDetailPixels;
end;

Utils.updateStrawHaulmArea = function(preparingOutputId, x, z, x1, z1, x2, z2)
	local IDs,detailId = {},g_currentMission.terrainDetailId;
	table.insert(IDs,g_currentMission.cultivatorChannel);
	table.insert(IDs,g_currentMission.sowingChannel);
	table.insert(IDs,g_currentMission.ploughChannel);
	local dx, dz, dwidthX, dwidthZ, dheightX, dheightZ = Utils.getXZWidthAndHeight(detailId, x, z, x1, z1, x2, z2)
	for i = 1, table.getn(IDs) do
		setDensityMaskedParallelogram(preparingOutputId, dx, dz, dwidthX, dwidthZ, dheightX, dheightZ, 0, 1, detailId, IDs[i], 1, 1)
	end
end;

function ChoppedStraw_Register:deleteMap() end;
function ChoppedStraw_Register:keyEvent(unicode, sym, modifier, isDown) end;
function ChoppedStraw_Register:mouseEvent(posX, posY, isDown, isUp, button) end;
function ChoppedStraw_Register:draw() end;

addModEventListener(ChoppedStraw_Register);
