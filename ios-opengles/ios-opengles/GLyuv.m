//
//  OpenglesRender.m
//  ios-opengles
//
//  Created by wzj on 2018/12/16.
//  Copyright © 2018年 wzj. All rights reserved.
//

#import "GLyuv.h"
#import <GLKit/GLKit.h>
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

// The fragment shader.
// Do YUV to RGB565 conversion.
static const char gFragmentShader[] = {
    "#ifdef GL_ES\n"
    "precision mediump int;\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec2 textureOut;\n"
    "uniform sampler2D tex_y;\n"
    "uniform sampler2D tex_u;\n"
    "uniform sampler2D tex_v;\n"
    "void main(void) {\n"
    "    vec3 yuv;\n"
    "    vec3 rgb;\n"
    "    yuv.x = texture2D(tex_y, textureOut).r;\n"
    "    yuv.y = texture2D(tex_u, textureOut).r - 0.5;\n"
    "    yuv.z = texture2D(tex_v, textureOut).r - 0.5;\n"
    "    rgb = mat3( 1,       1,         1,\n"
    "                0,       -0.39465,  2.03211,\n"
    "                1.13983, -0.58060,  0) * yuv;\n"
    "    gl_FragColor = vec4(rgb, 1);\n"
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

typedef struct video_frame_t{
    uint8_t* y;
    uint8_t* u;
    uint8_t* v;
    
    int y_linesize;
    int u_linesize;
    int v_linesize;
    int width;
    int height;
    int y_bytes;
    int u_bytes;
    int v_bytes;
}video_frame_t;

typedef struct priv_data_t{
    int _win_width;
    int _win_height;
    video_frame_t frame;
    pthread_mutex_t frame_mutex;
    GLuint gTextureIds[3];
    GLuint gProgram;
    GLfloat mTextureVertices[8];
    GLfloat mVertexVertices[8];
    int texture_inited;
    int degree_;
}priv_data_t;

@interface GLyuv()
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
    
    if (r->degree_ == 90 || r->degree_ == 270) {
        vw = textureHeight;
        vh = textureWidth;
    }else{
        vw = textureWidth;
        vh = textureHeight;
    }
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
    int i = glGetUniformLocation(r->gProgram, "tex_y");
    checkGlError("glGetUniformLocation");
    glUniform1i(i, 0); /* Bind Ytex to texture unit 0 */
    checkGlError("glUniform1i Ytex");
    
    i = glGetUniformLocation(r->gProgram, "tex_u");
    checkGlError("glGetUniformLocation Utex");
    glUniform1i(i, 1); /* Bind Utex to texture unit 1 */
    checkGlError("glUniform1i Utex");
    
    i = glGetUniformLocation(r->gProgram, "tex_v");
    checkGlError("glGetUniformLocation");
    glUniform1i(i, 2); /* Bind Vtex to texture unit 2 */
    checkGlError("glUniform1i");
    
    glGenTextures(3, r->gTextureIds); //Generate  the Y, U and V texture
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

static void InitializeTexture(int name, int id, int width, int height) {
    glActiveTexture(name);
    glBindTexture(GL_TEXTURE_2D, id);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0,
                      GL_LUMINANCE, GL_UNSIGNED_BYTE, NULL);
}


#define FREEIF(x) do{if(x!=NULL){free(x);x=NULL;}}while(0)
static void render_frame(priv_data_t* r, video_frame_t* frame){
    if(frame->y == NULL){
        return;
    }

    pthread_mutex_lock(&r->frame_mutex);
    if((r->frame.height != frame->height) ||
                (r->frame.width != frame->width) ||
                (r->frame.y == NULL)
                ){
        FREEIF(r->frame.y);
        r->frame.height = frame->height;
        r->frame.width = frame->width;
        r->frame.y_linesize = frame->y_linesize;
        r->frame.u_linesize = frame->u_linesize;
        r->frame.v_linesize = frame->v_linesize;
        r->frame.y_bytes = frame->y_linesize*frame->height;
        r->frame.u_bytes = r->frame.y_bytes/4;
        r->frame.v_bytes = r->frame.y_bytes/4;
        r->frame.y = (uint8_t*)malloc(r->frame.y_bytes + r->frame.u_bytes + r->frame.v_bytes);
        if(r->frame.y == NULL){
            goto end;
        }
        r->frame.u = r->frame.y + r->frame.y_bytes;
        r->frame.v = r->frame.u + r->frame.u_bytes;
    }
    memcpy(r->frame.y, frame->y, r->frame.y_bytes);
    memcpy(r->frame.u, frame->u, r->frame.u_bytes);
    memcpy(r->frame.v, frame->v, r->frame.v_bytes);
end:
    pthread_mutex_unlock(&r->frame_mutex);
    //TODO invoke update
}

static void gl_resize(priv_data_t* r, int w, int h){
    r->_win_width = w;
    r->_win_height = h;
    glViewport(0, 0, w, h);
    checkGlError("glViewport");
}

static void gl_redraw(void* arg, int w, int h){
    //ENTRY();
    priv_data_t* r = (priv_data_t*)arg;
    pthread_mutex_lock(&r->frame_mutex);
    //LOGI("entry lock");
    if (r->frame.y == NULL) {

    } else {
        int width_ = r->frame.y_linesize;
        int height_ = r->frame.height;
        //LOGI<<"got yuv, width: " << width_ << ", height: " << height_;
        if(!r->texture_inited){
            NSLog(@"init opengles, frame: %d x %d", width_, height_);
            gl_resize(r, w, h);
            initTexture(r,r->frame.width,  width_,  height_);
            InitializeTexture(GL_TEXTURE0, r->gTextureIds[0], width_, height_);
            InitializeTexture(GL_TEXTURE1, r->gTextureIds[1], width_ / 2, height_ / 2);
            InitializeTexture(GL_TEXTURE2, r->gTextureIds[2], width_ / 2, height_ / 2);
            glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
            glClearColor(0, 0, 0, 1);
            checkGlError("glClear");
            
            glUseProgram(r->gProgram);
            checkGlError("glUseProgram");
            r->texture_inited = TRUE;
        }
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, r->gTextureIds[0]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width_, height_, GL_LUMINANCE,
                                   GL_UNSIGNED_BYTE,  r->frame.y);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, r->gTextureIds[1]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width_>>1, height_>>1, GL_LUMINANCE,
                                   GL_UNSIGNED_BYTE,  r->frame.u);
    
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, r->gTextureIds[2]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width_>>1, height_>>1, GL_LUMINANCE,
                                   GL_UNSIGNED_BYTE,  r->frame.v);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    pthread_mutex_unlock(&r->frame_mutex);
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

@implementation GLyuv

@end
