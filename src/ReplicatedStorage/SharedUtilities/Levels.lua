--[[
local function GetDecimalCount(Number)
	local SplitStr = tostring(Number):split(".")[2]
	if SplitStr then
		return #(SplitStr)
	else
		return 0
	end
end

local function Round(Number, DecimalPlaces)
	DecimalPlaces = math.pow(10, DecimalPlaces or 0)
	Number = Number * DecimalPlaces

	if Number >= 0 then
		Number = math.floor(Number + 0.5)
	else 
		Number = math.ceil(Number - 0.5)
	end

	return Number / DecimalPlaces
end

	function Levels.GetXPFromLevel(Level, ShouldRound)
	ShouldRound = ShouldRound or false
	
	local XP = (10 * Level - 50 * math.floor(Level/10)) * (math.floor(Level/10) + 1)
	
	if ShouldRound then
		local DecimalPlacesCount = GetDecimalCount(Level)
		return Round(XP, DecimalPlacesCount)
	else
		return XP
	end
end


function Levels.GetLevelFromXP(XP)
	local Level = 0
	local RoundedXP = math.round(XP / 10) * 10
	local CurrentSlope = 10
	local Minimum = 0
	
	if XP == 0 then
		return 0
	elseif XP == 10 then
		return 1
	end

	while true do
		local CalculatedXP = Levels.GetXPFromLevel(Level)
		if Level % 10 == 0 then
			if Level >= 10 then
				CurrentSlope += 10
			end

            -- The points of the next min and the next max.
			local MinPoint = Vector2.new(Levels.GetXPFromLevel(Level + 1), Level + 1)
			local MaxPoint = Vector2.new(MinPoint.X + 9 * CurrentSlope, MinPoint.Y + 9)

            -- The points of the current max and the next min.
            local SubMinPoint = MinPoint - Vector2.new(CalculatedXP, Level)
            local SubMaxPoint = MinPoint

            local PointFallsInSubDomain = XP <= SubMaxPoint.X and XP >= SubMinPoint.X

            if PointFallsInSubDomain then
				local Time = math.abs(XP - SubMinPoint.X) / (SubMaxPoint - SubMinPoint).Magnitude
				local Approximation = SubMinPoint:Lerp(SubMaxPoint, Time)
                --local DecimalPlacesCount = GetDecimalCount(XP)
				--local RoundedApproximation = Round(Approximation.Y, DecimalPlacesCount)
				--return RoundedApproximation
                return Approximation.Y
			end

            local PointFallsInDomain = XP <= MaxPoint.X and XP >= MinPoint.X

			if PointFallsInDomain then
				local Time = math.abs(XP - MinPoint.X) / (MaxPoint - MinPoint).Magnitude
				local Approximation = MinPoint:Lerp(MaxPoint, Time)
				--local DecimalPlacesCount = GetDecimalCount(XP)
				--local RoundedApproximation = Round(Approximation.Y, DecimalPlacesCount)
				--return RoundedApproximation
                return Approximation.Y
			end
		end
		Level += 1
	end
end
]]

local Levels = {}

function Levels.GetRemainingXPForLevel(CurrentLevel, GoalLevel)
    return Levels.GetXPFromLevel(GoalLevel) - Levels.GetXPFromLevel(CurrentLevel)
end

function Levels.GetXPFromLevel(Level)
	local Decimal = math.abs(Level - math.floor(Level))
	local TruncatedLevel = math.floor(Level)
	local Slope = 10
	local XP = 0
	for i = 1, Level do
		if i % 10 == 0 then
			Slope += 10
		end
		
		if i == TruncatedLevel then
			XP += Slope * Decimal
			break
		end
		
		XP += Slope
	end
	return XP + 10
end

function Levels.GetLevelFromXP(XP)
	local Level = 1
	local Slope = 10
	local Level10XP = Levels.GetXPFromLevel(10)
	
	if XP <= 0 then
		return 0
	end
	
	while true do
		if XP < Level10XP then
			local MinSD = Levels.GetXPFromLevel(Level)
			local MaxSD = MinSD + Slope * 10
			local PointFallsInSD = XP >= MinSD and XP <= MaxSD
			local Difference = MaxSD - MinSD
			local TowardNext = XP - MinSD
			if PointFallsInSD then
				return Level + TowardNext / Difference * 10
			end
		end
		
		if Level % 10 == 0 then
			Slope += 10
			
			local MinSD = Levels.GetXPFromLevel(Level)
			local MaxSD = MinSD + Slope * 10
			local PointFallsInSD = XP >= MinSD and XP <= MaxSD
			local Difference = MaxSD - MinSD
			local TowardNext = XP - MinSD
			
			if PointFallsInSD then
				return Level + TowardNext / Difference * 10
			end
		end
		
		Level += 1
	end
end

return Levels