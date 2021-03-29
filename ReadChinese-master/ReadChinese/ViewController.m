//
//  ViewController.m
//  ReadChinese
//
//  Created by Ashen on 15/12/10.
//  Copyright © 2015年 Ashen. All rights reserved.
//

#import "ViewController.h"
#import "ASConvertor.h"
#import <AFNetworking/AFNetworking.h>
#import "XMLReader.h"

@interface ViewController()

@property (weak) IBOutlet NSTextField *txtShowPath;
@property (weak) IBOutlet NSTextField *txtShowOutPath;
@property (weak) IBOutlet NSScrollView *txtShowChinese;
@property (weak) IBOutlet NSButton *deleteInOneFile;
@property (weak) IBOutlet NSButton *deleteInAllFiles;
@property (weak) IBOutlet NSButton *tradition;

@property (nonatomic, strong)  NSTextView *txtView;
@property(nonatomic,assign)int index;
@property (nonatomic, strong)  NSArray  * stringArr;
//@property (nonatomic, strong)  NSDictionary  * stringDict;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.txtShowPath.editable = NO;
    self.txtShowOutPath.editable = NO;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - action
- (IBAction)deleteInAllFiles:(NSButton *)sender {
    self.deleteInOneFile.state = 0;
}

- (IBAction)deleteInOneFile:(NSButton *)sender {
    self.deleteInAllFiles.state = 0;
}


- (IBAction)OpenFile:(NSButton *)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    if ([oPanel runModal] == NSOKButton) {
        NSString *path = [[[[[oPanel URLs] objectAtIndex:0] absoluteString] componentsSeparatedByString:@":"] lastObject];
        path = [[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByExpandingTildeInPath];
        if (sender.tag == 100) {
            self.txtShowPath.placeholderString = path;
        } else {
            self.txtShowOutPath.placeholderString = path;
        }
    }
}

- (IBAction)exportAction:(id)sender {
    [self readFiles:self.txtShowPath.placeholderString];
}

#pragma mark - Method
- (void)showTxt:(NSMutableString *)txt {
    self.txtView.string = txt;
    self.txtShowChinese.documentView = _txtView;
}


- (void)readFiles:(NSString *)str {
    if (self.txtShowPath.placeholderString.length == 0 || self.txtShowOutPath.placeholderString.length == 0) {
        [self showTxt:[@"亲，选择路径没？" mutableCopy]];
        return;
    }
    [self showTxt:[@"开始导出" mutableCopy]];
    
    NSData *xmlData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/strings.xml",self.txtShowPath.placeholderString]];
    NSError *error = nil;
    if (error) {
        
        NSLog(@"error : %@", error);
    }
    
    NSDictionary *result = [XMLReader dictionaryForXMLData:xmlData error:&error];
    NSLog(@"result : %@", result);
    NSDictionary * resourcesDic = [result objectForKey:@"resources"];
    NSArray * stringArr = [resourcesDic objectForKey:@"string"];
    
//    NSMutableArray * marr = [NSMutableArray array];
//    for (NSDictionary * dic in stringArr) {
//        [marr addObjectsFromArray:[dic objectForKey:@"item"]];
//    }
    
    self.stringArr = stringArr;
//    self.stringDict = mdic;
//    self.stringKeyArr = mdic.allKeys;
    self.index = 0;
    if (stringArr.count > 0) {
        [self replaceText:stringArr[self.index]];
    }
}

-(void)replaceText:(NSDictionary *)valueDic{

    if (self.index > self.stringArr.count-1) {
        return;
    }
    
    NSString * value = [valueDic objectForKey:@"text"];
    if ([value containsString:@"\%"]) {
        [self replaceNextText];
        return;
    }


    NSString * bdkey = @"20210322000737899";
    NSString * bdscret = @"i3d4IZ0Vy20I_NXL9l_J";
    NSMutableDictionary * mparameters = [NSMutableDictionary dictionary];
    [mparameters setValue:value forKey:@"q"];
    [mparameters setValue:@"zh" forKey:@"from"];
    [mparameters setValue:@"vie" forKey:@"to"];
    [mparameters setValue:bdkey forKey:@"appid"];
    UInt salt = arc4random();
    [mparameters setValue:@(salt) forKey:@"salt"];
    NSString * sign = [NSString stringWithFormat:@"%@%@%u%@",bdkey,value,salt,bdscret];
    NSString * md5Cmd = [NSString stringWithFormat:@"md5 -s '%@'",sign];
    NSArray * arr = [[self cmd:md5Cmd] componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString * signMd5;
    if (arr.count > 2) {
        signMd5 = arr[arr.count -2];
    }
    [mparameters setValue:signMd5 forKey:@"sign"];
    
    
    value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@"\\\\n"];
    value = [value stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    value = [NSString stringWithFormat:@">%@<",value];
    __weak ViewController * weak_self = self;
    [[AFHTTPSessionManager manager] GET:@"http://api.fanyi.baidu.com/api/trans/vip/translate" parameters:mparameters headers:@{} progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray * result= [responseObject objectForKey:@"trans_result"];
//        NSMutableString * mori = [NSMutableString string];
//        NSMutableString * mdes = [NSMutableString string];
//        for (NSDictionary * dic in result) {
//            [mori appendString:[dic objectForKey:@"src"]];
//            [mori appendString:@"\\n"];
//            [mdes appendString:];
//            [mdes appendString:@"\\n"];
//        }
//        if (result.count >= 1) {
//            [mori deleteCharactersInRange:NSMakeRange(mori.length-2, 2)];
//            [mdes deleteCharactersInRange:NSMakeRange(mdes.length-2, 2)];
//        }
        NSString * dsoc =[result.firstObject objectForKey:@"dst"];

//        NSString * src = [mori stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString * dst = [NSString stringWithFormat:@">%@<", [dsoc stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
        dst = [dst stringByReplacingOccurrencesOfString:@"'" withString:@""];
        dst = [dst stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
        
     
        if (dst.length == 2) {
            NSLog(@"error=====%@",value);
        }else{
//            NSString * sh2 = [NSString stringWithFormat:@"sed -i '' -e s/'%@'/'%@'/g `grep %@ -rl %@`",text,dst,text,self.txtShowOutPath.placeholderString];
            
            NSString * sh2 = [NSString stringWithFormat:@"sed -i '' -e s/'%@'/'%@'/g %@/strings.xml",value,dst,self.txtShowOutPath.placeholderString];
            [weak_self cmd:sh2];
        }
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,15*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//            [weak_self replaceNextText];
//        });
     
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error=====%@",value);
    }];
    NSLog(@"=========end");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,0.15*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [weak_self replaceNextText];
    });
}

-(void)replaceNextText{
    self.index ++;
    if (self.index > self.stringArr.count-1) {
        return;
    }
    [self replaceText:self.stringArr[self.index]];
}


-(NSDictionary *)transform:(id)obj{
    if ([obj isKindOfClass:NSDictionary.class]) {
        return (NSDictionary *)obj;
    }else{
        return nil;
    }
}

#pragma mark - getter / setter
- (NSTextView *)txtView {
    if (_txtView) {
        return _txtView;
    }
    _txtView = [[NSTextView alloc]initWithFrame:CGRectMake(0, 0, 335, 190)];
    [_txtView setMinSize:NSMakeSize(0.0, 190)];
    [_txtView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [_txtView setVerticallyResizable:YES];
    [_txtView setHorizontallyResizable:NO];
    [_txtView setAutoresizingMask:NSViewWidthSizable];
    [[_txtView textContainer]setContainerSize:NSMakeSize(335,FLT_MAX)];
    [[_txtView textContainer]setWidthTracksTextView:YES];
    [_txtView setFont:[NSFont fontWithName:@"Helvetica" size:12.0]];
    [_txtView setEditable:NO];
    return _txtView;
}

- (NSString *)cmd:(NSString *)cmd
{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
//    NSLog(@"[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]; %@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

@end
