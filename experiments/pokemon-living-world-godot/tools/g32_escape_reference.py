#!/usr/bin/env python3
"""Independent geometry probe for G3.2, NOT the Godot battle runtime."""
from math import hypot
WEST,EAST,NORTH,SOUTH=85.,875.,145.,373.
LOOKAHEAD=9
DT=.1
SPEED=57.
FOE_SPEED=43.
FACTOR=1.08
MARGIN=45.
DIRECTIONS=((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1))
CORNERS=((92,152),(868,152),(92,366),(868,366))

def clamp(x,y):return max(WEST,min(EAST,x)),max(NORTH,min(SOUTH,y))
def clearance(x,y):return min(x-WEST,EAST-x,y-NORTH,SOUTH-y)
def score(pos,foe,heading,previous=(0.,0.)):
    x,y=pos;fx,fy=foe;hx,hy=heading
    target=x+hx*SPEED*DT*FACTOR*LOOKAHEAD,y+hy*SPEED*DT*FACTOR*LOOKAHEAD
    reachable=clamp(*target)
    clipped=hypot(reachable[0]-target[0],reachable[1]-target[1])
    traveled=hypot(reachable[0]-x,reachable[1]-y)
    px,py=reachable[0]-fx,reachable[1]-fy
    norm=hypot(px,py)
    budget=FOE_SPEED*DT*LOOKAHEAD
    if norm>budget:px,py=px*budget/norm,py*budget/norm
    predicted=fx+px,fy+py
    gap=hypot(reachable[0]-predicted[0],reachable[1]-predicted[1])
    safety=max(0.,min(clearance(*reachable),MARGIN*2))
    continuity=2.5*max(0,hx*previous[0]+hy*previous[1])
    return gap*1.6+traveled*.22+safety*.75-clipped*3+continuity

def choose(pos,foe,previous=(0.,0.)):
    normalized=((x/hypot(x,y),y/hypot(x,y)) for x,y in DIRECTIONS)
    return max(normalized,key=lambda h:score(pos,foe,h,previous))

def is_wall_risk(pos,foe):
    dx,dy=foe[0]-pos[0],foe[1]-pos[1];length=hypot(dx,dy)
    if length<.001:return False
    raw=(pos[0]-dx/length*SPEED*DT*LOOKAHEAD,pos[1]-dy/length*SPEED*DT*LOOKAHEAD)
    target=clamp(*raw)
    return hypot(target[0]-raw[0],target[1]-raw[1])>.1 or clearance(*target)<MARGIN

def step(pos,foe,heading):
    return clamp(pos[0]+heading[0]*SPEED*DT*FACTOR,pos[1]+heading[1]*SPEED*DT*FACTOR)

def probe_corner(index,steps=14):
    pos=CORNERS[index]
    foe=(pos[0]+(80 if pos[0]<480 else -80),pos[1]+(80 if pos[1]<260 else -80))
    old=pos;replans=0;heading=(0.,0.)
    for tick in range(steps):
        if tick%18==0 or hypot(*(a-b for a,b in zip(step(pos,foe,heading),pos)))<SPEED*DT*FACTOR*.7:
            heading=choose(pos,foe,heading);replans+=1
        pos=step(pos,foe,heading)
    return {'corner':index,'start':old,'end':pos,'traveled':hypot(pos[0]-old[0],pos[1]-old[1]),'replans':replans,'wall_clearance':clearance(*pos)}
