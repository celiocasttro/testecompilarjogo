package com.dramovix.desvie;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Color;
import android.view.MotionEvent;
import android.view.View;
import android.content.Context;
import java.util.ArrayList;
import java.util.Random;

public class MainActivity extends Activity {
    @Override public void onCreate(Bundle state) { super.onCreate(state); getWindow().getDecorView().setSystemUiVisibility(5894 | 1024 | 512); setContentView(new GameView(this)); }

    static class Block { float x, y, size, speed; Block(float x,float y,float size,float speed){this.x=x;this.y=y;this.size=size;this.speed=speed;} }
    static class GameView extends View {
        Paint p = new Paint(3); Random random = new Random(); ArrayList<Block> blocks = new ArrayList<>();
        float playerX, playerY, playerSize = 42, spawnTimer = 0; int score = 0, best = 0; long last = 0; boolean over = false;
        int bg = Color.rgb(12,18,38);
        GameView(Context c){super(c);setLayerType(View.LAYER_TYPE_SOFTWARE,null);}
        void text(Canvas c,String s,float x,float y,float size,int color){p.setColor(color);p.setTextSize(size);p.setTextAlign(Paint.Align.CENTER);p.setTypeface(android.graphics.Typeface.create("sans-serif-rounded",android.graphics.Typeface.BOLD));c.drawText(s,x,y,p);}
        @Override protected void onDraw(Canvas c){super.onDraw(c); long now=System.currentTimeMillis(); float dt=last==0?0:Math.min(.04f,(now-last)/1000f);last=now;
            c.drawColor(bg); float w=getWidth(),h=getHeight(); if(playerX==0){playerX=w/2;playerY=h*.82f;}
            p.setColor(Color.rgb(24,34,63)); for(int i=0;i<8;i++) c.drawCircle((i*137)%Math.max(1,(int)w), (i*211+(now/60)%Math.max(1,(int)h))%Math.max(1,(int)h),2,p);
            if(!over){spawnTimer+=dt;if(spawnTimer>.72f){spawnTimer=0;float s=30+random.nextInt(28);blocks.add(new Block(s/2+random.nextFloat()*Math.max(1,w-s),-s,s,210+Math.min(score,500)*.5f));}
                for(int i=blocks.size()-1;i>=0;i--){Block b=blocks.get(i);b.y+=b.speed*dt;if(b.y>h+60){blocks.remove(i);score++;if(score>best)best=score;continue;}float dx=Math.abs(b.x-playerX),dy=Math.abs(b.y-playerY);if(dx<(b.size+playerSize)*.48f&&dy<(b.size+playerSize)*.48f)over=true;}}
            for(Block b:blocks){p.setColor(Color.rgb(255,83,112));c.drawRoundRect(b.x-b.size/2,b.y-b.size/2,b.x+b.size/2,b.y+b.size/2,9,9,p);p.setColor(Color.rgb(255,170,180));c.drawRoundRect(b.x-b.size/2+5,b.y-b.size/2+5,b.x+b.size/2-5,b.y+b.size/2-5,6,6,p);}
            p.setColor(Color.rgb(77,220,255));c.drawRoundRect(playerX-playerSize/2,playerY-playerSize/2,playerX+playerSize/2,playerY+playerSize/2,14,14,p);p.setColor(Color.WHITE);c.drawCircle(playerX,playerY,7,p);
            text(c,"DESVIE DOS BLOCOS",w/2,55,23,Color.WHITE);p.setTextAlign(Paint.Align.LEFT);text(c,"PONTOS: "+score,w/2,95,18,Color.rgb(135,230,255));
            if(over){p.setColor(0xCC080D1B);c.drawRect(0,0,w,h,p);text(c,"FIM DE JOGO",w/2,h*.42f,34,Color.WHITE);text(c,"Pontuação: "+score,w/2,h*.48f,22,Color.rgb(135,230,255));text(c,"Toque para jogar novamente",w/2,h*.55f,18,Color.WHITE);}
            else {text(c,"ARRASTE O QUADRADO",w/2,h*.94f,14,0xFF9AA9D4);}
            postInvalidateDelayed(16);
        }
        @Override public boolean onTouchEvent(MotionEvent e){float x=e.getX(),y=e.getY();if(e.getAction()==MotionEvent.ACTION_DOWN){if(over){blocks.clear();score=0;spawnTimer=0;over=false;last=0;}playerX=x;playerY=Math.max(getHeight()*.35f,Math.min(getHeight()*.9f,y));invalidate();return true;}if(e.getAction()==MotionEvent.ACTION_MOVE){playerX=Math.max(playerSize/2,Math.min(getWidth()-playerSize/2,x));playerY=Math.max(getHeight()*.2f,Math.min(getHeight()*.92f,y));invalidate();return true;}return true;}
    }
}
