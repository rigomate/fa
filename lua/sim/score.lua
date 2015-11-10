scoreInterval = 10

local scoreData = {current={}, historical={}}
local scoreOption = ScenarioInfo.Options.Score or "no"
local ArmyScore = {}

function UpdateScoreData(newData)
    scoreData.current = table.deepcopy(newData)
end

function CalculateBrainScore(brain)
    local commanderKills = brain:GetArmyStat("Enemies_Commanders_Destroyed",0).Value
    local massSpent = brain:GetArmyStat("Economy_TotalConsumed_Mass",0.0).Value
    local massProduced = brain:GetArmyStat("Economy_TotalProduced_Mass",0.0).Value -- not currently being used
    local energySpent = brain:GetArmyStat("Economy_TotalConsumed_Energy",0.0).Value
    local energyProduced = brain:GetArmyStat("Economy_TotalProduced_Energy",0.0).Value -- not currently being used
    local massValueDestroyed = brain:GetArmyStat("Enemies_MassValue_Destroyed",0.0).Value
    local massValueLost = brain:GetArmyStat("Units_MassValue_Lost",0.0).Value
    local energyValueDestroyed = brain:GetArmyStat("Enemies_EnergyValue_Destroyed",0.0).Value
    local energyValueLost = brain:GetArmyStat("Units_EnergyValue_Lost",0.0).Value

    -- helper variables to make equation more clear
    local excessMassProduced = massProduced - massSpent -- not currently being used
    local excessEnergyProduced = energyProduced - energySpent -- not currently being used
    local energyValueCoefficient = 20
    local commanderKillBonus = commanderKills + 1 -- not currently being used

    -- score components calculated
    local resourceProduction = ((massSpent) + (energySpent / energyValueCoefficient)) / 2
    local battleResults = (((massValueDestroyed - massValueLost- (commanderKills * 18000)) + ((energyValueDestroyed - energyValueLost - (commanderKills * 5000000)) / energyValueCoefficient)) / 2)
    if battleResults < 0 then
        battleResults = 0
    end

    -- score calculated
    local score = math.floor(resourceProduction + battleResults + (commanderKills * 5000))

    return score
end

function ScoreHistoryThread()
    while true do
        WaitSeconds(scoreInterval)
        table.insert(scoreData.historical, table.deepcopy(scoreData.current))
    end
end

function ScoreThread()
    for index, brain in ArmyBrains do
        ArmyScore[index] = {
            general = {
                score = 0,
                mass = 0,
                lastReclaimedMass = 0,
                lastReclaimedEnergy = 0,
                energy = 0,
                kills = {
                    count = 0,
                    mass = 0,
                    energy = 0
                },
                built = {
                    count = 0,
                    mass = 0,
                    energy = 0
                },
                lost = {
                    count = 0,
                    mass = 0,
                    energy = 0
                },
                currentunits = {
                    count = 0
                },
                currentcap = {
                    count = 0
                }
            },

            units = {
                cdr = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                sacu = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                land = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                air = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                naval = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                structures = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                transportation = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                engineer = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                tech1 = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                tech2 = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                tech3 = {
                    kills = 0,
                    built = 0,
                    lost = 0
                },
                experimental = {
                    kills = 0,
                    built = 0,
                    lost = 0
                }
            },

            resources = {
                massin = {
                    total = 0,
                    rate = 0
                },
                massout = {
                    total = 0,
                    rate = 0
                },
                energyin = {
                    total = 0,
                    rate = 0
                },
                energyout = {
                    total = 0,
                    rate = 0
                },
                massover = 0,
                energyover = 0
            }
        }
    end
    
    ForkThread(ScoreDisplayResourcesThread)

    while true do
        for index, brain in ArmyBrains do
            ArmyScore[index].general.score = CalculateBrainScore(brain)

            ArmyScore[index].general.mass = brain:GetArmyStat("Economy_TotalProduced_Mass", 0.0).Value
            ArmyScore[index].general.energy = brain:GetArmyStat("Economy_TotalProduced_Energy", 0.0).Value
            ArmyScore[index].general.currentunits.count = brain:GetArmyStat("UnitCap_Current", 0.0).Value
            ArmyScore[index].general.currentcap.count = brain:GetArmyStat("UnitCap_MaxCap", 0.0).Value

            ArmyScore[index].general.kills.count = brain:GetArmyStat("Enemies_Killed", 0.0).Value
            ArmyScore[index].general.kills.mass = brain:GetArmyStat("Enemies_MassValue_Destroyed", 0.0).Value
            ArmyScore[index].general.kills.energy = brain:GetArmyStat("Enemies_EnergyValue_Destroyed", 0.0).Value

            ArmyScore[index].general.built.count = brain:GetArmyStat("Units_History", 0.0).Value
            ArmyScore[index].general.built.mass = brain:GetArmyStat("Units_MassValue_Built", 0.0).Value
            ArmyScore[index].general.built.energy = brain:GetArmyStat("Units_EnergyValue_Built", 0.0).Value
            ArmyScore[index].general.lost.count = brain:GetArmyStat("Units_Killed", 0.0).Value
            ArmyScore[index].general.lost.mass = brain:GetArmyStat("Units_MassValue_Lost", 0.0).Value
            ArmyScore[index].general.lost.energy = brain:GetArmyStat("Units_EnergyValue_Lost", 0.0).Value

            ArmyScore[index].resources.massin.total = brain:GetArmyStat("Economy_TotalProduced_Mass", 0.0).Value
            ArmyScore[index].resources.massout.total = brain:GetArmyStat("Economy_TotalConsumed_Mass", 0.0).Value
            ArmyScore[index].resources.massout.rate = brain:GetArmyStat("Economy_Output_Mass", 0.0).Value
            ArmyScore[index].resources.massover = brain:GetArmyStat("Economy_AccumExcess_Mass", 0.0).Value
           
            ArmyScore[index].resources.energyin.total = brain:GetArmyStat("Economy_TotalProduced_Energy", 0.0).Value
            ArmyScore[index].resources.energyout.total = brain:GetArmyStat("Economy_TotalConsumed_Energy", 0.0).Value
            ArmyScore[index].resources.energyout.rate = brain:GetArmyStat("Economy_Output_Energy", 0.0).Value
            ArmyScore[index].resources.energyover = brain:GetArmyStat("Economy_AccumExcess_Energy", 0.0).Value

            for unitId, stats in brain:GetUnitStats() do
                if ArmyScore[index].units[unitId] == nil then
                    ArmyScore[index].units[unitId] = {}
                end

                for statName, value in stats do
                    ArmyScore[index].units[unitId][statName] = value
                end
            end

            ArmyScore[index].units.transportation.kills = brain:GetBlueprintStat("Enemies_Killed", categories.TRANSPORTATION)
            ArmyScore[index].units.transportation.built = brain:GetBlueprintStat("Units_History", categories.TRANSPORTATION)
            ArmyScore[index].units.transportation.lost = brain:GetBlueprintStat("Units_Killed", categories.TRANSPORTATION)

            ArmyScore[index].units.land.kills = brain:GetBlueprintStat("Enemies_Killed", categories.LAND)
            ArmyScore[index].units.land.built = brain:GetBlueprintStat("Units_History", categories.LAND)
            ArmyScore[index].units.land.lost = brain:GetBlueprintStat("Units_Killed", categories.LAND)
            ArmyScore[index].units.air.kills = brain:GetBlueprintStat("Enemies_Killed", categories.AIR)
            ArmyScore[index].units.air.built = brain:GetBlueprintStat("Units_History", categories.AIR)
            ArmyScore[index].units.air.lost = brain:GetBlueprintStat("Units_Killed", categories.AIR)
            ArmyScore[index].units.naval.kills = brain:GetBlueprintStat("Enemies_Killed", categories.NAVAL)
            ArmyScore[index].units.naval.built = brain:GetBlueprintStat("Units_History", categories.NAVAL)
            ArmyScore[index].units.naval.lost = brain:GetBlueprintStat("Units_Killed", categories.NAVAL)

            ArmyScore[index].units.cdr.kills = brain:GetBlueprintStat("Enemies_Killed", categories.COMMAND)
            ArmyScore[index].units.cdr.built = brain:GetBlueprintStat("Units_History", categories.COMMAND)
            ArmyScore[index].units.cdr.lost = brain:GetBlueprintStat("Units_Killed", categories.COMMAND)
            ArmyScore[index].units.sacu.kills = brain:GetBlueprintStat("Enemies_Killed", categories.SUBCOMMANDER)
            ArmyScore[index].units.sacu.built = brain:GetBlueprintStat("Units_History", categories.SUBCOMMANDER)
            ArmyScore[index].units.sacu.lost = brain:GetBlueprintStat("Units_Killed", categories.SUBCOMMANDER)

            ArmyScore[index].units.engineer.kills = brain:GetBlueprintStat("Enemies_Killed", categories.ENGINEER)
            ArmyScore[index].units.engineer.built = brain:GetBlueprintStat("Units_History", categories.ENGINEER)
            ArmyScore[index].units.engineer.lost = brain:GetBlueprintStat("Units_Killed", categories.ENGINEER)
            ArmyScore[index].units.tech1.kills = brain:GetBlueprintStat("Enemies_Killed", categories.TECH1)
            ArmyScore[index].units.tech1.built = brain:GetBlueprintStat("Units_History", categories.TECH1)
            ArmyScore[index].units.tech1.lost = brain:GetBlueprintStat("Units_Killed", categories.TECH1)
            ArmyScore[index].units.tech2.kills = brain:GetBlueprintStat("Enemies_Killed", categories.TECH2)
            ArmyScore[index].units.tech2.built = brain:GetBlueprintStat("Units_History", categories.TECH2)
            ArmyScore[index].units.tech2.lost = brain:GetBlueprintStat("Units_Killed", categories.TECH2)
            ArmyScore[index].units.tech3.kills = brain:GetBlueprintStat("Enemies_Killed", categories.TECH3)
            ArmyScore[index].units.tech3.built = brain:GetBlueprintStat("Units_History", categories.TECH3)
            ArmyScore[index].units.tech3.lost = brain:GetBlueprintStat("Units_Killed", categories.TECH3)
            ArmyScore[index].units.experimental.kills = brain:GetBlueprintStat("Enemies_Killed", categories.EXPERIMENTAL)
            ArmyScore[index].units.experimental.built = brain:GetBlueprintStat("Units_History", categories.EXPERIMENTAL)
            ArmyScore[index].units.experimental.lost = brain:GetBlueprintStat("Units_Killed", categories.EXPERIMENTAL)

            ArmyScore[index].units.structures.kills = brain:GetBlueprintStat("Enemies_Killed", categories.STRUCTURE)
            ArmyScore[index].units.structures.built = brain:GetBlueprintStat("Units_History", categories.STRUCTURE)
            ArmyScore[index].units.structures.lost = brain:GetBlueprintStat("Units_Killed", categories.STRUCTURE)

            WaitSeconds(0.1)
        end

        WaitSeconds(3)
        UpdateScoreData(ArmyScore)
        SyncScores()
    end
end

function ScoreDisplayResourcesThread()
    -- For certain stats, we need to do this every tick. We can't for all because it is quite heavy CPU
    -- We don't need to sync every tick though, just make sure the number is right
    while true do
        for index, brain in ArmyBrains do
            local reclaimedMass = brain:GetArmyStat("Economy_Reclaimed_Mass", 0.0).Value
            local massReclaimRate = reclaimedMass - ArmyScore[index].general.lastReclaimedMass
            ArmyScore[index].resources.massin.rate = brain:GetArmyStat("Economy_Income_Mass", 0.0).Value - massReclaimRate
            ArmyScore[index].general.lastReclaimedMass = reclaimedMass

            local reclaimedEnergy = brain:GetArmyStat("Economy_Reclaimed_Energy", 0.0).Value
            local energyReclaimRate = reclaimedEnergy - ArmyScore[index].general.lastReclaimedEnergy
            ArmyScore[index].resources.energyin.rate = brain:GetArmyStat("Economy_Income_Energy", 0.0).Value - energyReclaimRate
            ArmyScore[index].general.lastReclaimedEnergy = reclaimedEnergy
        end
        WaitSeconds(0.1)
    end
end

local observer = false
function SyncScores()
    observer = observer or GetFocusArmy() == -1

    local victory = import('/lua/victory.lua')

    Sync.SendStats = victory.sendStats
    if Sync.SendStats then
        -- Reset the flag so that stats are only sent once.
        -- Do it only when Sync.SendStats was set to true to prevent race conditions.
        victory.sendStats = false
    end

    if observer or import('/lua/victory.lua').gameOver or Sync.SendStats then
        Sync.FullScoreSync = true
        Sync.ScoreAccum = scoreData
        Sync.Score = scoreData.current
    else
        local my_army = GetFocusArmy()

        for index, brain in ArmyBrains do
            Sync.Score[index] = {}
            Sync.Score[index].general = {}

            if my_army == index then
                Sync.Score[index].general.currentunits = {}
                Sync.Score[index].general.currentunits.count = ArmyScore[index].general.currentunits.count
                Sync.Score[index].general.currentcap = {}
                Sync.Score[index].general.currentcap.count = ArmyScore[index].general.currentcap.count
            end

            if scoreOption ~= 'no' then
                Sync.Score[index].general.score = ArmyScore[index].general.score
            else
                Sync.Score[index].general.score = -1
            end
        end

    end
end

function init()
    ForkThread(ScoreThread)    
    ForkThread(ScoreHistoryThread)
end
