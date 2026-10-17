#!/usr/bin/env python3
"""Independent *offline reference* for G3.0 1v1 utility policy.

Godot's native GDScript implementation owns real gameplay. This reference
checks seed determinism, termination, damage ownership and avoidance of deadlock.
Never claim Python output is an actual Godot execution trace.
"""
from __future__ import annotations
from dataclasses import dataclass
from math import hypot
import argparse
import json

TICK_LIMIT = 600
SEED_JUMP = 104729
WALLS = (85.0, 875.0, 145.0, 373.0)
STATS = [dict(id=25, hp=85, power=12, speed=57., range=78., cooldown_ticks=11, windup_ticks=3),
         dict(id=94, hp=94, power=11, speed=43., range=85., cooldown_ticks=13, windup_ticks=4)]
ORDERS = ('FREE', 'AGGRESSIVE', 'KEEP_DISTANCE', 'DEFENSIVE')


def rand(seed: int):
    seed = seed & 2147483647 or 1
    while True:
        seed = (seed * 1103515245 + 12345) & 2147483647
        yield seed


@dataclass
class Unit:
    idx: int
    hp: int
    max_hp: int
    power: int
    speed: float
    reach: float
    cooldown_ticks: int
    windup_ticks: int
    x: float
    y: float
    cooldown: int = 0
    strike_at: int = -1
    dodge_ready_at: int = 0
    guard_until: int = 0
    action: str = 'APPROACH'
    hits: int = 0
    misses: int = 0


def simulate(seed: int, order: str = 'FREE'):
    if order not in ORDERS:
        raise ValueError('Unsupported 1v1 order: ' + order)
    randoms = rand(seed)
    v0 = next(randoms) % 59 - 29
    v1 = next(randoms) % 59 - 29
    units = []
    for i, s in enumerate(STATS):
        units.append(Unit(i, s['hp'], s['hp'], s['power'], s['speed'], s['range'],
                          s['cooldown_ticks'], s['windup_ticks'],
                          250.0 if i == 0 else 710.0, 264.0 + [v0,v1][i]))
    events=[]
    digest=7
    winner=-1
    reason=''
    total_hits=total_misses=0
    counts={a:0 for a in ("APPROACH","DODGE","GUARD","CIRCLE","WINDUP","ATTACK")}
    for tick in range(1, TICK_LIMIT+1):
        for u in units:
            u.cooldown=max(0,u.cooldown-1)
        intents=[]
        for i, me in enumerate(units):
            foe=units[1-i]
            if me.strike_at>=0:
                intents.append('WINDUP'); continue
            dist=hypot(me.x-foe.x, me.y-foe.y)
            telegraph=foe.strike_at>=tick
            ready=me.cooldown<=0
            scores=dict(APPROACH=-100.,ATTACK=-100.,GUARD=-100.,DODGE=-100.,CIRCLE=10.)
            if dist>me.reach-6:
                scores['APPROACH']=80.+min(8.,dist/95.)
            elif ready:
                scores['ATTACK']=110.
            else:
                scores['CIRCLE']=30.
            if telegraph and dist<foe.reach+12:
                if tick>=me.dodge_ready_at and me.hp*2<me.max_hp:
                    scores['DODGE']=115.
                elif me.guard_until<tick and (i==1 or order=='DEFENSIVE'):
                    scores['GUARD']=107. if i==1 else 118.
            if i==0:
                if order=='AGGRESSIVE':
                    scores['ATTACK']=scores['ATTACK']+15 if ready else -100.
                    scores['GUARD']=-100.
                elif order=='KEEP_DISTANCE':
                    if telegraph and dist<foe.reach+30:
                        scores['DODGE']=119. if tick>=me.dodge_ready_at else -100.
                    if dist>me.reach:
                        scores['APPROACH']=max(scores['APPROACH'],92.)
                elif order=='DEFENSIVE':
                    scores['GUARD']=scores['GUARD']+5. if scores['GUARD']>0 else -100.
            intents.append(max(('ATTACK','GUARD','DODGE','APPROACH','CIRCLE'),key=lambda a:scores[a]))
        for i, me in enumerate(units):
            foe=units[1-i]
            action=intents[i]
            me.action=action
            counts[action]+=1
            dx,dy=foe.x-me.x,foe.y-me.y
            d=hypot(dx,dy)
            dx,dy=(dx/d,dy/d) if d>0.001 else (1.,0.)
            if action=='APPROACH':
                me.x+=dx*me.speed*.1
                me.y+=dy*me.speed*.1
            elif action=='DODGE':
                me.x-=dx*me.speed*.1*2.1
                me.y-=dy*me.speed*.1*2.1
                me.dodge_ready_at=tick+22
            elif action=='GUARD':
                me.guard_until=tick+4
            elif action=='CIRCLE':
                me.x+=-dy*me.speed*.1*.12
                me.y+= dx*me.speed*.1*.12
            elif action=='ATTACK':
                me.strike_at=tick+me.windup_ticks
                me.cooldown=max(5,me.cooldown_ticks-2) if i==0 and order=='AGGRESSIVE' else me.cooldown_ticks
                events.append(('WINDUP',tick,i))
            me.x=min(max(me.x,WALLS[0]),WALLS[1]); me.y=min(max(me.y,WALLS[2]),WALLS[3])
        scheduled=[]
        for i,me in enumerate(units):
            if me.strike_at==tick:
                foe=units[1-i]
                dist=hypot(me.x-foe.x, me.y-foe.y)
                guarded=foe.guard_until>=tick
                damage=max(1,me.power//2) if guarded else me.power
                scheduled.append((i,1-i,dist<=me.reach+12,damage))
                me.strike_at=-1
        for i,j,landed,dmg in scheduled:
            if landed:
                units[j].hp=max(0,units[j].hp-dmg)
                units[i].hits+=1
                total_hits+=1
                events.append(('HIT',tick,i,j,dmg))
            else:
                units[i].misses+=1
                total_misses+=1
                events.append(('MISS',tick,i,j))
        stamp=tick
        for u in units:
            stamp+=u.hp*103+int(u.x*10)*11+int(u.y*10)*7
        digest=(digest*31+stamp)%2147483647
        a,b=units[0].hp,units[1].hp
        if a<=0 or b<=0 or tick>=TICK_LIMIT:
            reason='KO' if a<=0 or b<=0 else 'TIMEOUT_HP_RATIO'
            if a<=0 and b<=0:winner=2
            elif a<=0:winner=1
            elif b<=0:winner=0
            elif abs(a/units[0].max_hp - b/units[1].max_hp)<.0001:winner=2
            else:winner=0 if a/units[0].max_hp>b/units[1].max_hp else 1
            break
    return dict(seed=seed,order=order,winner=winner,tick=tick,reason=reason,
                hp=[u.hp for u in units],hits=total_hits,misses=total_misses,digest=digest,
                events=events,start_y=[264+v0,264+v1],actions=counts)


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--seed',type=int,default=20261017)
    parser.add_argument('--order',choices=ORDERS,default='FREE')
    a=parser.parse_args()
    out=simulate(a.seed,a.order)
    out['events']=out['events'][-10:]
    print(json.dumps(out,indent=2,ensure_ascii=False))
