local spawnedHorses = {}

function SpawnHorses(horsemodel, horsecoords, heading)
    
    local spawnedHorse = CreatePed(horsemodel, horsecoords.x, horsecoords.y, horsecoords.z - 1.0, heading, false, false, 0, 0)
    SetEntityAlpha(spawnedHorse, 0, false)
    SetRandomOutfitVariation(spawnedHorse, true)
    SetEntityCanBeDamaged(spawnedHorse, false)
    SetEntityInvincible(spawnedHorse, true)
    FreezeEntityPosition(spawnedHorse, true)
    SetBlockingOfNonTemporaryEvents(spawnedHorse, true)
    -- set relationship group between horse and player
    SetPedRelationshipGroupHash(spawnedHorse, GetPedRelationshipGroupHash(spawnedHorse))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedHorse), `PLAYER`)

    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedHorse, i, false)
        end
    end

    return spawnedHorse
end

CreateThread(function()
    for key, value in pairs(Config.HorseSettings) do
        local coords = value.horsecoords
        local newpoint = lib.points.new({
            coords = coords,
            distance = Config.DistanceSpawn,
            model = value.horsemodel,
            ped = nil,
            price = value.horseprice,
            heading = coords.w,
            horsename = value.horsename
        })
        
        newpoint.onEnter = function(self)
            if not self.ped then
                lib.requestModel(self.model, 10000)
                self.ped = SpawnHorses(self.model, self.coords, self.heading) -- spawn horse
                pcall(function ()
                    exports['rsg-target']:AddTargetEntity(self.ped, {
                        options = {
                            {
                                icon = "fas fa-horse-head",
                                label = self.horsename..' $'..self.price,
                                targeticon = "fas fa-eye",
                                action = function()
                                    local dialog = lib.inputDialog('Horse Setup', {
                                        { type = 'input', label = 'Horse Name', required = true },
                                        {
                                            type = 'select',
                                            label = 'Horse Gender',
                                            options = {
                                                { value = 'male',   label = 'Gelding' },
                                                { value = 'female', label = 'Mare' }
                                            }
                                        }
                                    })
                
                                    if not dialog then return end
                
                                    local setHorseName = dialog[1]
                                    local setHorseGender = dialog[2]
                                    
                                    if setHorseName and setHorseGender then
                                        TriggerServerEvent('rsg-horses:server:BuyHorse', self.price, self.model, value.stableid, setHorseName, setHorseGender)
                                    else
                                        return
                                    end
                                end
                            }
                        },
                        distance = 2.5,
                    })
                end)
            end
        end

        newpoint.onExit = function(self)
            if self.ped and DoesEntityExist(self.ped) then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(self.ped, i, false)
                    end
                end
                DeleteEntity(self.ped)
                self.ped = nil
            end
        end
        
        spawnedHorses[key] = newpoint
    end
end)

-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for key, value in pairs(spawnedHorses) do
        if value.ped and DoesEntityExist(value.ped) then
            DeleteEntity(value.ped)
        end

        spawnedHorses[key] = nil
    end
end)
