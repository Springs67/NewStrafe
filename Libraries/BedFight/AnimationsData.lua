local doAnim = function(animId: number)
    return 'rbxassetid://' .. tostring(animId)
end

local v1 = {
    Build = {
        Place = {
            Animation = doAnim(132824246314688),
            ViewModel = doAnim(116711748176924)
        }
    },
    Swords = {
        Swing = {
            Animation = doAnim(123800159244236),
            ViewModel = doAnim(80138703077151)
        },
        Throw = {
            Animation = doAnim(112647901028195),
            ViewModel = doAnim(92580106700773)
        }
    },
    Mace = {
        Swing = {
            Animation = doAnim(123800159244236),
            ViewModel = doAnim(70627219820436)
        },
        Smash = {
            Animation = doAnim(78293755986958),
            ViewModel = doAnim(73873263555313)
        }
    },
    Katanas = { {
            Animation = doAnim(123800159244236),
            ViewModel = doAnim(89566327625992)
        }, {
            Animation = doAnim(121539268395045),
            ViewModel = doAnim(81877230308347)
        } },
    Daggers = { {
            Animation = doAnim(125647890626762),
            ViewModel = doAnim(86920412656075)
        }, {
            Animation = doAnim(70931463871860),
            ViewModel = doAnim(125237858746897)
        } },
    ["Battle Axe"] = {
        Swing = {
            Animation = doAnim(73956227653463),
            ViewModel = doAnim(78000921252326)
        },
        Throw = {
            Animation = doAnim(112647901028195),
            ViewModel = doAnim(92580106700773)
        }
    },
    Spears = {
        Hold = {
            Animation = doAnim(139910061842959)
        },
        Swing = {
            Animation = doAnim(108157536795882),
            ViewModel = doAnim(124860807529028)
        }
    },
    Mining = {
        Mine = {
            Animation = doAnim(99440694775362),
            ViewModel = doAnim(126156901192649)
        }
    },
    Bow = {
        Charge = {
            ViewModel = doAnim(92719863624451)
        },
        Aim = {
            ViewModel = doAnim(107233852716078)
        },
        Shoot = {
            ViewModel = doAnim(105395625117501)
        }
    },
    Crossbow = {
        Charge = {
            ViewModel = doAnim(97072392163167)
        },
        Aim = {
            ViewModel = doAnim(79824191356979)
        },
        Shoot = {
            ViewModel = doAnim(88816665007799)
        }
    },
    Fireball = {
        Shoot = {
            Animation = doAnim(132824246314688),
            ViewModel = doAnim(70627219820436)
        }
    },
    Teleorb = {
        Shoot = {
            ViewModel = doAnim(70627219820436)
        }
    },
    Hotdog = {
        Charge = {
            ViewModel = doAnim(108691521370690)
        },
        Aim = {
            ViewModel = doAnim(81711293508051)
        },
        Shoot = {
            ViewModel = doAnim(89874662847661)
        }
    },
    Food = {
        Eat = {
            Animation = doAnim(79132931841789),
            ViewModel = doAnim(72239923385553)
        }
    },
    Balloon = {
        Deploy = {
            Animation = doAnim(132824246314688),
            ViewModel = doAnim(70627219820436)
        }
    }
};

return v1;