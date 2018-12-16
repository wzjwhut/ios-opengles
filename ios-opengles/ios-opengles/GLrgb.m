//
//  OpenglesRender.m
//  ios-opengles
//
//  Created by wzj on 2018/12/16.
//  Copyright © 2018年 wzj. All rights reserved.
//

#import "GLrgb.h"

#import <pthread.h>

static const char gVertexShader[] = {
    "attribute vec4 vertexIn;    \n"
    "attribute vec2 textureIn;   \n"
    "varying vec2 textureOut;    \n"
    "void main(void)             \n"
    "{                           \n"
    "    gl_Position = vertexIn; \n"
    "    textureOut = textureIn; \n"
    "}                           \n"
};

static const char gFragmentShader[] = {
    "#ifdef GL_ES\n"
    "precision mediump float; \n"
    "#endif\n"
    "void main(void) {\n"
    "    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0); \n"
    "}\n"
};


static const GLfloat gVertexVertices[] ={
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    1.0f, 1.0f
};

//0 degree
static const GLfloat gTextureVertices_0[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f
};

/** 为了和其它版本的代码保持统一，所以仍然使用C风格的代码 */

typedef struct priv_data_t{
    int _win_width;
    int _win_height;
    uint8_t* rgb_data;
    GLuint gTextureIds[1];
    GLuint gProgram;
    GLfloat mTextureVertices[8];
    GLfloat mVertexVertices[8];
    int texture_inited;
}priv_data_t;

@interface GLrgb()
{
    priv_data_t priv;
}
@end

static void checkGlError(const char* op);
static GLuint createProgram(const char* pVertexSource, const char* pFragmentSource) ;

static int initTexture(priv_data_t* r, int textureWidth, int linesize, int textureHeight){
    r->gProgram = createProgram(gVertexShader, gFragmentShader);
    if (!r->gProgram) {
        return -1;
    }
    
    int gPositionHandle = glGetAttribLocation(r->gProgram, "vertexIn");
    checkGlError("glGetAttribLocation aPosition");
    
    int gTextureHandle = glGetAttribLocation(r->gProgram, "textureIn");
    checkGlError("glGetAttribLocation aTextureCoord");
    
    memcpy(r->mVertexVertices, gVertexVertices, sizeof(r->mVertexVertices));
    
    memcpy(r->mTextureVertices, gTextureVertices_0, sizeof(r->mTextureVertices));
    float clipText = ((float)((linesize - textureWidth)))/linesize;
    r->mTextureVertices[2] -= clipText;
    r->mTextureVertices[6] -= clipText;
    
    
    int vw, vh;
    vw = textureWidth;
    vh = textureHeight;
    float clipH, clipW;
    int x1 = vw*r->_win_height;
    int x2 = vh*r->_win_width;
    
    if (x1>x2) {
        clipH = x2/(float)x1;
        clipW = 1.0;
    }else if(x1<x2){
        clipW = x1/(float)x2;
        clipH = 1.0;
    }else{
        clipW = 1.0;
        clipH = 1.0;
    }
    for (int i=0; i<8; i+=2) {
        r->mVertexVertices[i] = r->mVertexVertices[i]*clipW;
        r->mVertexVertices[i+1] = r->mVertexVertices[i+1]*clipH;
    }
    
    glVertexAttribPointer(gPositionHandle, 2, GL_FLOAT, 0, 0, r->mVertexVertices);
    checkGlError("glVertexAttribPointer aPosition");
    
    glEnableVertexAttribArray(gPositionHandle);
    checkGlError("glEnableVertexAttribArray positionHandle");
    
    glVertexAttribPointer(gTextureHandle, 2, GL_FLOAT, 0, 0, r->mTextureVertices);
    checkGlError("glVertexAttribPointer maTextureHandle");
    glEnableVertexAttribArray(gTextureHandle);
    checkGlError("glEnableVertexAttribArray textureHandle");
    
    glUseProgram(r->gProgram);

    glGenTextures(1, r->gTextureIds); //Generate  the Y, U and V texture
    return 0;
}


static void printGLString(const char *name, GLenum s) {
    const char *v = (const char *)glGetString(s);
    NSLog(@"GL %s = %s", name, v);
}

static void checkGlError(const char* op) {
    for (GLint error = glGetError(); error; error
         = glGetError()) {
        NSLog(@"after %s, glError: %d", op, error);
    }
}

static GLuint loadShader(GLenum shaderType, const char* pSource) {
    GLuint shader = glCreateShader(shaderType);
    if (shader) {
        glShaderSource(shader, 1, &pSource, NULL);
        glCompileShader(shader);
        GLint compiled = 0;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen) {
                char* buf = (char*) malloc(infoLen);
                if (buf) {
                    glGetShaderInfoLog(shader, infoLen, NULL, buf);
                    free(buf);
                }
                glDeleteShader(shader);
                shader = 0;
            }
        }
    }
    return shader;
}

static GLuint createProgram(const char* pVertexSource, const char* pFragmentSource) {
    GLuint vertexShader = loadShader(GL_VERTEX_SHADER, pVertexSource);
    if (!vertexShader) {
        NSLog(@"create vertex shader failed");
        return 0;
    }
    
    GLuint pixelShader = loadShader(GL_FRAGMENT_SHADER, pFragmentSource);
    if (!pixelShader) {
        NSLog(@"create pixel shader failed");
        glDeleteShader(vertexShader);
        return 0;
    }
    
    GLuint program = glCreateProgram();
    if (program) {
        glAttachShader(program, vertexShader);
        checkGlError("glAttachShader");
        glAttachShader(program, pixelShader);
        checkGlError("glAttachShader");
        glLinkProgram(program);
        GLint linkStatus = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
            GLint bufLength = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufLength);
            if (bufLength) {
                char* buf = (char*) malloc(bufLength);
                if (buf) {
                    glGetProgramInfoLog(program, bufLength, NULL, buf);
                    NSLog(@"Could not link program:%s", buf);
                    free(buf);
                }
            }
            glDeleteShader(vertexShader);
            glDeleteShader(pixelShader);
            glDeleteProgram(program);
            program = 0;
        }
    }
    return program;
}

static void InitializeTexture(int name, int id) {
    glActiveTexture(name);
    glBindTexture(GL_TEXTURE_2D, id);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}


static void gl_draw(priv_data_t* r,
                    uint8_t* rgb,
                    int width, int height){
    if(!r->texture_inited){
        NSLog(@"init texture, %d, %d", r->_win_width, r->_win_height);
        glViewport(0, 0, r->_win_width, r->_win_height);
        initTexture(r, width,  width,  height);
        InitializeTexture(GL_TEXTURE0, r->gTextureIds[0]);
        checkGlError("glClear");
        
        glUseProgram(r->gProgram);
        checkGlError("glUseProgram");
        r->texture_inited = TRUE;
    }
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(GL_TEXTURE_2D, r->gTextureIds[0]);
    checkGlError("glBindTexture");
    NSLog(@"glTexImage2D: %d, %d", width, height);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, r->rgb_data);
    checkGlError("glTexImage2D");
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    checkGlError("glDrawArrays");
}



static void release_gl_resources(priv_data_t* r){
    if (r->gProgram != 0) {
        glDeleteProgram(r->gProgram);
        r->gProgram = 0;
    }
    if (r->gTextureIds[0] != 0) {
        glDeleteTextures(3, r->gTextureIds);
        r->gTextureIds[0] = 0;
    }
}


@implementation GLrgb

-(instancetype) initWith:( CGRect*) rect
{
    NSLog(@"init GLrgb, %f, %f", rect->size.width, rect->size.height);
    self->priv._win_width = rect->size.width;
    self->priv._win_height = rect->size.height;
    return self;
}


-(void) drawRGB: (uint8_t*) rgb_data width: (int) width height: (int) height
{
    NSLog(@"drow rgb");
    gl_draw(&self->priv, rgb_data, width, height);
}
@end
