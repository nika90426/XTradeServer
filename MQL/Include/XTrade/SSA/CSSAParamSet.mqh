//+------------------------------------------------------------------+
//|                                                  SSAObserver.mq5 |
//|                               Copyright 2016, Roman Korotchenko  |
//|                        https://login.mql5.com/ru/users/Solitonic |
//|                                           Revision December 2016 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2016, Roman Korotchenko"
#property link        "https://login.mql5.com/ru/users/Solitonic"
#property version     "1.00"
#include <Strings\String.mqh>
#include <XTrade\SSA\CSSADefines.mqh>

// ОПРЕДЕЛЕНЫ  КЛАССЫ ================================
class CFileSet;
class CSSACDParamSet;
class CSSATrendParamSet;
class CSSAStochParamSet;
//====================================================
//#include <SSA\SSALibHeader.mqh>
/*
#import "SSA/SSABayesLib.ex5"
   string GetValueAsString (int strIdx, CString &StrData[]);
   double GetValueAsDouble (int strIdx, CString &StrData[]);
   int    GetValueAsInteger(int strIdx, CString &StrData[]);
   color  GetValueAsColor  (int strIdx, CString &StrData[]);
#import

*/
class CFileSet
{
   private:
   
   protected:

     //string  InpFilePath; // путь к файлу с параметрами
     CString StrData[];   // строки с данными
     int    StrCnt;
   
   public:
     int  DataLength;
     bool LoadOK;
     long MagicNumber;
     
     CFileSet();
    ~CFileSet();
    
    int FileLoad(string path);
    

};
//-------------------------------------------------------------------------------

CFileSet::CFileSet()
{
   ArrayResize(StrData,100,300);
   DataLength = 0;
}
//-------------------------------------------------------------------------------
CFileSet::~CFileSet()
{
   ArrayFree(StrData);
}
//-------------------------------------------------------------------------------

int CFileSet::FileLoad(string path)
{
   // ФАЙЛЫ ДОЛЖНЫ ЛЕЖАТЬ В ПАПКЕ Files или ее поддиректориях! (Ограничение MQL5)
    LoadOK = false;
    StrCnt = 0;
   //--- откроем файл 
   ResetLastError(); 
   int file_handle=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI); 
   if(file_handle!=INVALID_HANDLE) 
     { 
        string str;
                    
        while(!FileIsEnding(file_handle)) 
        {
         str = FileReadString(file_handle) ; 
         StrData[StrCnt].Assign(str);         
         //PrintFormat(str);  PrintFormat(StrData[StrCnt].Str()); 
         StrCnt++;
        }  
       FileClose(file_handle);
       LoadOK = true;
     }
   else {   
      LoadOK = false;
      PrintFormat("Файл %s не обнаружен. Исправьте путь",path); 
      PrintFormat("Путь к файлу: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH)); 
   }  
   
   return StrCnt; 
}
//-------------------------------------------------------------------------------




//===============================================================================
class CSSATrendParamSet : public CFileSet
{
   private:
   
   
   public:
     int    ForecastMethod;
     int    SegmentLength;
     int    SW;
     double FastNoiseLevel;
     double SlowNoiseLevel;
     int    DataConvertMethod;
     int    FrcstConvertMethod;
     int    ForecastUpdateON;
     int    RefreshPeriod;
     int    ForecastPoints;
     int    BackwardShift;
     int    NWindVolat;
     string VISUAL_OPTIONS;
     
     int NormalColor;
     int PredictColor;
     
     string INTERFACE;
   
    int LengthWithPrediction;
    
    CSSATrendParamSet() {
          ForecastMethod=2;  SegmentLength=240;   SW=3;
          FastNoiseLevel=0.25;
          RefreshPeriod=10; ForecastPoints=10; BackwardShift=0; 
          
          VISUAL_OPTIONS="* VISUAL OPTIONS *";
            NormalColor=16711680;   
            PredictColor=13749760; 
          
          INTERFACE ="* INTERFACE *";
          
          LengthWithPrediction = SegmentLength+ForecastPoints;
    };
    
    int FileSetLoadLimited(string fpath);
    int FileSetLoad(string fpath);
};
//-------------------------------------------------------------------------------

int CSSATrendParamSet::FileSetLoadLimited(string fpath)
{
 int  cnt = -1, ni  = FileLoad(fpath);
 
  LoadOK = false;
 if(ni>0) {    /*   
   ForecastMethod = GetValueAsInteger(++cnt, StrData); 
   SegmentLength  = GetValueAsInteger(++cnt, StrData);
               SW = GetValueAsInteger(++cnt, StrData);
   FastNoiseLevel = GetValueAsDouble (++cnt, StrData);
   RefreshPeriod  = GetValueAsInteger(++cnt, StrData);
   ForecastPoints = GetValueAsInteger(++cnt, StrData);
    BackwardShift = GetValueAsInteger(++cnt, StrData);
    
   VISUAL_OPTIONS = GetValueAsString (++cnt, StrData);
     
     NormalColor  = GetValueAsInteger(++cnt, StrData);
     PredictColor = GetValueAsInteger(++cnt, StrData);     
   
        INTERFACE = GetValueAsString (++cnt, StrData);
     
      MagicNumber = GetValueAsInteger(++cnt, StrData);    
       
    LengthWithPrediction = SegmentLength+ForecastPoints;
    LoadOK = true;*/
 }
 
 return ni;
}
//---------------------------------------------------------------------------------

int CSSATrendParamSet::FileSetLoad(string fpath)
{
 int  cnt = -1, ni  = FileLoad(fpath);
 
  LoadOK = false;
 if(ni>0) {      
  /* ForecastMethod = GetValueAsInteger(++cnt, StrData);
   SegmentLength  = GetValueAsInteger(++cnt, StrData);
               SW = GetValueAsInteger(++cnt, StrData);
   FastNoiseLevel = GetValueAsDouble(++cnt, StrData);
   SlowNoiseLevel = GetValueAsDouble(++cnt, StrData);
   FrcstConvertMethod = GetValueAsInteger(++cnt, StrData);
   ForecastUpdateON = GetValueAsInteger(++cnt, StrData);
   RefreshPeriod  = GetValueAsInteger(++cnt, StrData);
   ForecastPoints = GetValueAsInteger(++cnt, StrData);
    BackwardShift = GetValueAsInteger(++cnt, StrData);
    
   VISUAL_OPTIONS = GetValueAsString(++cnt, StrData);
     
   NormalColor  = GetValueAsInteger(++cnt, StrData);
   PredictColor = GetValueAsInteger(++cnt, StrData);     
   
      INTERFACE = GetValueAsString(++cnt, StrData);
    
    MagicNumber = GetValueAsInteger(++cnt, StrData);    
    
       
    LengthWithPrediction = SegmentLength+ForecastPoints;
    LoadOK = true;*/
 }
 
 return ni;
}

//===============================================================================   
//
//===============================================================================   
class CSSACDParamSet : public CFileSet
{
   private:
   
   
   public:
     int    ForecastMethod;
     int    SegmentLength;
     int    SW;
     double FastNoiseLevel;
     double SlowNoiseLevel;
     int    InpSignalSMA;
     int    DataConvertMethod;
     int    DataConvertMethodAux;
     int    ForecastUpdateON;
     int    RefreshPeriod;
     int    BackwardShift;
     int    SimulatingON;
     
     string INTERFACE, AUXILIARY;
   
     int LengthWithPrediction, ForecastPoints;
     double limBuy, limSell; 
    
     
   
    CSSACDParamSet() {
       ForecastMethod = 2;
       SegmentLength=512; FastNoiseLevel=0.35 ; SlowNoiseLevel=0.55;
       DataLength = 512;
       SW=4;
       InpSignalSMA=4; 
       DataConvertMethod   = ConvLnDif;
       DataConvertMethodAux= ConvNorm;
       ForecastUpdateON=0;       
       RefreshPeriod=30; 
       BackwardShift=0;
       SimulatingON =0;
       
       INTERFACE = "* INTERFACE *";
       MagicNumber = 19661021401;
       
       ForecastPoints = 15; // Фиксировано в Limited-версии
       
       AUXILIARY = "* AUXILIARY SIGNAL *";
       limBuy = 10; 
       limSell= 15;
       
       LengthWithPrediction = SegmentLength + ForecastPoints; 
    };
    
    int FileSetLoadLimited(string fpath);
    int FileSetLoad(string fpath);
};
//-------------------------------------------------------------------------------

int CSSACDParamSet::FileSetLoadLimited(string fpath)
{
   int cnt = -1,  ni  = FileLoad(fpath);
     LoadOK = false;
     if(ni>0) {
       /*   
       SegmentLength  = GetValueAsInteger(++cnt, StrData);
       FastNoiseLevel = GetValueAsDouble (++cnt, StrData);
       SlowNoiseLevel = GetValueAsDouble(++cnt, StrData);
       InpSignalSMA   = GetValueAsInteger(++cnt, StrData);
       DataConvertMethod   = GetValueAsInteger(++cnt, StrData);
       DataConvertMethodAux= GetValueAsInteger(++cnt, StrData);
        ForecastUpdateON   = GetValueAsInteger(++cnt, StrData);
       RefreshPeriod  = GetValueAsInteger(++cnt, StrData);
       BackwardShift  = GetValueAsInteger(++cnt, StrData);
       
          INTERFACE   = GetValueAsString(++cnt, StrData);
          MagicNumber = GetValueAsInteger(++cnt, StrData);          
       
       LengthWithPrediction = SegmentLength+ForecastPoints;
       LoadOK = true;*/
     }
     
  return ni;     
}
//-------------------------------------------------------------------------------

int CSSACDParamSet::FileSetLoad(string fpath)
{
   int cnt = -1,  ni  = FileLoad(fpath);
     LoadOK = false;
     if(ni>0) {
/*       ForecastMethod = GetValueAsInteger(++cnt, StrData);  
       SegmentLength  = GetValueAsInteger(++cnt, StrData);
                   SW = GetValueAsInteger(++cnt, StrData);
       FastNoiseLevel = GetValueAsDouble (++cnt, StrData);
       SlowNoiseLevel = GetValueAsDouble(++cnt, StrData);
       InpSignalSMA   = GetValueAsInteger(++cnt, StrData);
       DataConvertMethod   = GetValueAsInteger(++cnt, StrData);
       DataConvertMethodAux= GetValueAsInteger(++cnt, StrData);
        ForecastUpdateON   = GetValueAsInteger(++cnt, StrData);
       RefreshPeriod  = GetValueAsInteger(++cnt, StrData);
       ForecastPoints = GetValueAsInteger(++cnt, StrData);
       BackwardShift  = GetValueAsInteger(++cnt, StrData);
       
          INTERFACE   = GetValueAsString (++cnt, StrData);
          MagicNumber = GetValueAsInteger(++cnt, StrData);          
          
          AUXILIARY =  GetValueAsString(++cnt, StrData);
               limBuy = GetValueAsDouble (++cnt, StrData);
               limSell= GetValueAsDouble (++cnt, StrData);
    
          
       LengthWithPrediction = SegmentLength+ForecastPoints;
       LoadOK = true;*/
     }
     
  return ni;     
}
//===============================================================================


enum  ENUM_CONVERSION_LCL {    conv1 = 1,  // { S[i] }/Max(:) 
                               conv2 =20,  // { ln(S[i]-Smin+1) }/Max(:)      
                          }; 
//===============================================================================
class CSSAStochParamSet : public CFileSet
{
   private:
   
   
   public:
     int InpKPeriod;
     int InpDPeriod;
     int InpSlowing;
     int InpLevels;
     
     string SSA_OPTIONS;
       int    ForecastMethod;
       int    SegmentLength;
       int    SW;
       double FastNoiseLevelK;
       double FastNoiseLevelD;
       int    DataConvertMethod;
       int    ForecastUpdateON;
       int    RefreshPeriod;
       int    ForecastPoints;
       int    BackwardShift;
     
     string INTERFACE;
          // MagicNumber
     string VISUAL_OPTIONS;
          color NormalColorK, PredictColorK;
          color NormalColorD, PredictColorD;
     
        
    int LengthWithPrediction;
    ENUM_CONVERSION_LCL  FrcstConvertMethod;
    
    CSSAStochParamSet() {  StandardInit(); }
    
    void StandardInit()
    {
      InpKPeriod = 10; InpDPeriod =5;  InpSlowing=4; InpLevels=0;
      
      SSA_OPTIONS = "* SSA OPTIONS *";
         ForecastMethod=2;
         SegmentLength=256;
         SW=6;
         FastNoiseLevelK=0.2;
         FastNoiseLevelD=0.5;
         DataConvertMethod=1;
         ForecastUpdateON=2;
         RefreshPeriod=10;
            ForecastPoints=10; // Как в Limited
         BackwardShift=0;
         
         INTERFACE="* INTERFACE *";
            MagicNumber = 19661021100;

         VISUAL_OPTIONS= "* VISUAL OPTIONS *";
            NormalColorK=16711680;
            PredictColorK=25600;
            NormalColorD=17919;
            PredictColorD=16711935;
            
       LengthWithPrediction = SegmentLength + ForecastPoints; 
       FrcstConvertMethod   = conv1;     
     }     
     
     int FileSetLoad(string fpath);     
     int FileSetLoadLimited(string fpath);
};
//---------------------------------------------------------------------------    

/*
int CSSAStochParamSet::FileSetLoad(string fpath)
{
  int cnt = -1,  ni  = FileLoad(fpath);
     LoadOK = false;
     if(ni>0) {
       InpKPeriod = GetValueAsInteger(++cnt, StrData);
       InpDPeriod = GetValueAsInteger(++cnt, StrData);
       InpSlowing = GetValueAsInteger(++cnt, StrData);
       InpLevels  = GetValueAsInteger(++cnt, StrData);
     
     SSA_OPTIONS     = GetValueAsString (++cnt, StrData);
      ForecastMethod = GetValueAsInteger(++cnt, StrData);
      SegmentLength  = GetValueAsInteger(++cnt, StrData);
                  SW = GetValueAsInteger(++cnt, StrData);
      FastNoiseLevelK= GetValueAsDouble (++cnt, StrData);
      FastNoiseLevelD= GetValueAsDouble (++cnt, StrData);
   
   DataConvertMethod = GetValueAsInteger(++cnt, StrData);
   ForecastUpdateON  = GetValueAsInteger(++cnt, StrData);
   
   RefreshPeriod  = GetValueAsInteger(++cnt, StrData);
   ForecastPoints = GetValueAsInteger(++cnt, StrData);
    BackwardShift = GetValueAsInteger(++cnt, StrData);
    
         INTERFACE = GetValueAsString (++cnt, StrData);
       MagicNumber = GetValueAsInteger(++cnt, StrData); 
     
    VISUAL_OPTIONS = GetValueAsString   (++cnt, StrData);
       NormalColorK  = GetValueAsInteger(++cnt, StrData);
       PredictColorK = GetValueAsInteger(++cnt, StrData);
       NormalColorD  = GetValueAsInteger(++cnt, StrData);
       PredictColorD = GetValueAsInteger(++cnt, StrData);
       
     // НЕ ЗАБЫВАТЬ УСТАНОВИТЬ!   
     LengthWithPrediction = SegmentLength + ForecastPoints; 
     }
 
 return ni; 
}
*/
//---------------------------------------------------------------------------

int CSSAStochParamSet::FileSetLoadLimited(string fpath)
{

 return -1;

}
//---------------------------------------------------------------------------