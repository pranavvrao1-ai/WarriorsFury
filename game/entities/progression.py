"""Persistent player progression, points, and purchased upgrades."""


class PlayerProgression:
    SHOP_ITEMS = {
        "shield": {
            "name": "SHIELD",
            "cost": 150,
            "description": "Absorbs 60 damage.",
        },
        "armor": {
            "name": "ARMOR",
            "cost": 200,
            "description": "Reduces health damage by 25%.",
        },
        "health_core": {
            "name": "HEALTH CORE",
            "cost": 300,
            "description": "Full heal + maximum health 25.",
        },
        "overclock": {
            "name": "WEAPON OVERCLOCK",
            "cost": 250,
            "description": "Damage +50%, firing speed +25%.",
        },
    }

    def __init__(self):
        self.level = 1
        self.max_hp = 100
        self.hp = 100
        self.attack = 15
        self.speed = 270
        self.shoot_cooldown = 0.18

        self.points = 0
        self.rewards_claimed = set()
        self.purchased_upgrades = set()

        self.shield_capacity = 0
        self.armor_owned = False
        self.overclock_owned = False

    @property
    def credits(self):
        return self.points

    @credits.setter
    def credits(self, value):
        self.points = value

    def grant_stage_reward(self, stage_index):
        """Award increasing points on every stage clear."""
        points_earned = 100 * (stage_index + 1)
        self.points += points_earned

        messages = [
            f"LEVEL {stage_index + 1} CLEARED: +{points_earned} POINTS"
        ]

        # Character level-up rewards are granted only once per stage.
        if stage_index not in self.rewards_claimed:
            if stage_index == 0:
                self.level = 2
                self.max_hp += 25
                self.hp = min(self.max_hp, self.hp + 25)
                self.attack += 5
                messages.append(
                    "LEVEL UP: LV 2 | MAX HP +25 | ATTACK +5"
                )

            elif stage_index == 1:
                self.level = 3
                self.speed += 30
                self.shoot_cooldown *= 0.8
                messages.append(
                    "LEVEL UP: LV 3 | SPEED +30 | FIRE RATE +20%"
                )

            if stage_index in (0, 1):
                self.rewards_claimed.add(stage_index)

        return "\n".join(messages)

    def purchase(self, item_id):
        """Purchase an upgrade and return (success, message)."""
        if item_id not in self.SHOP_ITEMS:
            return False, "UNKNOWN ITEM."

        item = self.SHOP_ITEMS[item_id]

        if item_id in self.purchased_upgrades:
            return False, "UPGRADE ALREADY OWNED."

        if self.points < item["cost"]:
            return False, "NOT ENOUGH POINTS."

        self.points -= item["cost"]

        if item_id == "shield":
            self.shield_capacity = 60

        elif item_id == "armor":
            self.armor_owned = True

        elif item_id == "health_core":
            self.max_hp += 25
            self.hp = self.max_hp

        elif item_id == "overclock":
            self.attack = int(round(self.attack * 1.5))
            self.shoot_cooldown *= 0.75
            self.overclock_owned = True

        self.purchased_upgrades.add(item_id)
        return True, f"{item['name']} PURCHASED!"

    def get_shop_items(self):
        return self.SHOP_ITEMS
