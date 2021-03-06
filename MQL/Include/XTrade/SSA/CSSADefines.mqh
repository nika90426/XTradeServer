//+------------------------------------------------------------------+
//|                                                  CSSADefines.mqh |
//|                                Copyright 2016, Roman Korotchenko |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Roman Korotchenko"
#property link      "https://www.mql5.com"

#ifndef SERIA_DFLT_LENGTH 
#define SERIA_DFLT_LENGTH 32768    // Резервируемый по-умолчанию объем выделенной памяти 2^N;
#endif

#ifndef SERIA_LCL_LENGTH 
#define SERIA_LCL_LENGTH 8192     // Резервируемый по-умолчанию объем выделенной памяти 2^N;
#endif

#ifndef _EPSILON 
#define _EPSILON 1e-15  // условный "ноль" для отсечки расчетных погрешностей
#endif

#ifndef _EIF_NUM_MAX
#define _EIF_NUM_MAX 1000          // максимально допустимое число мод (обычно хватает 5-8 шт)
#endif

#ifndef _EV_EPSILON 
#define _EV_EPSILON 1e-8  // условный "ноль" для отсечки собственных значений
#endif

#ifndef _FFT_SSA
#define _FFT_SSA

enum ENUM_SSA_ALGORITHM
  { 
   AlgVector    =1, // Vector forecast
   AlgRecurrent =2  // Recurrent forecast
  };

enum ENUM_SEGMENT_N2
  { 
 //   f64  = 64,  // 64  
    f128 = 128,  // 128
    f256 = 256,   // 256
    f512 = 512,   // 512
    f1024 = 1024, // 1024
    f2048 = 2048  // 2048
    //f7 = 4096, // 4096
    // f8 = 8192  // 8192
  };
enum ENUM_SEGMENT_N2LIM
  {    
    SNL128 = 128,  // 128
    SNL256 = 256,  // 256
    SNL512 = 512   // 512 
  };  
  
enum ENUM_SSA_WIND
  { 
   swl2 =2,  // N/2
   swl25=3,  // N/2.5
   swl3 =4,  // N/3
   swl4 =6   // N/4      
  };
  
enum ENUM_CONVERSION
  { 
 //  d0 =0,   // { S[i] } as is 
   ConvNorm  = 1,  // { S[i] }/Max(:) 
   ConvDif   = 15, // { S[i]-S[i-1]) }/Max(:) 
   ConvLnDif = 20, // { ln(S[i]-Smin+1)}/Max(:) 
   ConvRel   = 3,  // { S[i]/S[i-1] }/Max(:) 
   ConvLnRel = 40  // { ln(S[i]/S[i-1] - Min(:)+1) }
  };  

enum ENUM_FRCSTSMOOTH
{
   FrsctSmooth0   = 0, // Smoothing off 
   FrsctSmoothMA3 = 3, // Smoothing MA(3) 
   FrsctPrTrMix   = 10,// Price and Trend mixing
   FrsctSmoothSSA = 20 // Smoothing by SSA
   //FrsctHistMix2    = 2 // Hist.Mix {1/6, 1/6, 1/6, 1/2}   
};


enum ENUM_FRCSTSMOOTH_STD 
{
   StdSmooth0   = 0, // Smoothing off 
   StdSmoothMA3 = 3  // Smoothing MA(3)  
};  

// ВСЕВОЗМОЖНЫЕ ВАРИАНТЫ ПРЕОБРАЗОВАНИЙ   (см.  CSimpleCalc::ForwardDataConversion)
enum ENUM_TRANSFORMATION  
  { 
   DataTrans0  = 0,  // { S[i] } as is 
   DataTrans1  = 1,  // { S[i] }/Max(:)  // нормализация в интервал [0,1]  со сдвигом на первый элемент к нулю
   DataTrans10 =10,  // { S[i] }/Max(:)   // нормализация в интервал [0,1] без сдвига
   DataTrans11 =11,	// [-1,1] при наличии разного знака   
   
   DataTrans15 =15,  // { S[i]-S[i-1] }/Max(:)
   DataTrans16 =16, 	// { S[i]-S[i-1] } без нормировки
   
   DataTrans2  =2,  	// сдвиг log-ие, нормализация и сдвиг на величину первого элемента ряда
   DataTrans20 =20,  // { ln(S[i]-Smin+1) }/Max(:)   // для рядов с нулевыми и отриц. значениями: сдвиг, log-ие, нормализация
   
   DataTrans3  =3,  // { S[i]/S[i-1] }/Max(:)
   
   DataTrans4  =4,  //
   DataTrans40 =40  //{ ln(S[i]/S[i-1] - Min(:)+1) }
  }; 
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

enum ENUM_TIMERECALC
  {
    TimeRecalc05 = 5,   // 5 sec
    TimeRecalc10 = 10,  // 10 sec
    TimeRecalc15 = 15,  // 15 sec
    TimeRecalc30 = 30,  // 30 sec
    TimeRecalc60 = 60   // 60 sec
  }; 
  
#endif