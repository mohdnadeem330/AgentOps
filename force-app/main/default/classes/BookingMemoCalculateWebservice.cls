@RestResource (urlMapping = '/query/bookingmemocalculate')
global with sharing class BookingMemoCalculateWebservice {
    /*
   { "memoCalculationInput":   [{
        "unitId":  "a0e7E00000FrRQv",
        "offerID":  "",
        "offerChanged":false,
        "paymentPlanId":  "",
        "calculationWrapper":    {
                    "discountPercentage": 0.00,
                    "rebatePercentage": 0.00,
                    "scWaiverYears": 0,
                    "pmFeeYear": 0,
                    "homeMaintenanceYears": 0,
                    "ADMFeePercentage": 0.00,
                    "subsidyPercentage": 0.00,
                    "internalCommissionPercentage": 0.00,
                    "brokerCommissionPercentage": 0.00,
                    "selectedVoucher": "",
                    "selectedMembership": "",
                    "isInit":true
                    
                }
        },
        {
        "unitId":  "a0e7E00000FrWZP",
        "offerID":  "",
        "offerChanged":false,
        "paymentPlanId":  "",
        "calculationWrapper":    {
                    "discountPercentage": 0.00,
                    "rebatePercentage": 0.00,
                    "scWaiverYears": 0,
                    "pmFeeYear": 0,
                    "homeMaintenanceYears": 0,
                    "ADMFeePercentage": 0.00,
                    "subsidyPercentage": 0.00,
                    "internalCommissionPercentage": 0.00,
                    "brokerCommissionPercentage": 0.00,
                    "selectedVoucher": "",
                    "selectedMembership": "",
                    "isInit":true
                }
        }],
        "opportunityId":"0067E00000H6tJe"

}
    */
    @HTTPPost
    global static void doPost(list<MemoCalculationInput> memoCalculationInput,String opportunityId ){
        RestContextHandler handler = new RestContextHandler(true);
        
        list<MemoCalculationWrapper> retrunObject = new list<MemoCalculationWrapper>();
        try {       
            Opportunity opRecord = [select id,BrokerAgencyAccount__c from opportunity where id = :opportunityId limit 1];
                  
            map<id,Unit__c> unitMap = new map<id,Unit__c>();
            map<id,list<OfferLines__c>> offerLineMap = new map<id,list<OfferLines__c>>();
            //Query for membership and VOucher
            list<OfferLines__c> activeOfferLines = [SELECT Id,Name,OfferOn__c,OfferType__c,OfferValue__c,VoucherName__c, OfferName__c FROM OfferLines__c where OfferType__c = :constants.OFFER_TYPE_VOUCHER and OfferName__r.IsActive__c=true and VoucherName__c!=null and OfferValue__c !=null] ;
            //For selected records
            
            for(MemoCalculationInput inputParam : memoCalculationInput){
                unitMap.put(inputParam.unitId,null);
                if(inputParam.offerID != null && inputParam.offerID!=''){
                    offerLineMap.put(inputParam.offerID,new list<OfferLines__c>());
                }
            }
            unitMap = new map<ID,Unit__c>([select id,SellingPrice__c,BuildingSectionName__r.HomeMaintenanceFee__c,BuildingSectionName__r.PropertyManagementFee__c,MarketLeaseRent__c,MeasuredArea__c,SaleableArea__c,AnticipatedServiceCharges__c from Unit__c where id in :unitMap.keySet() ]);
            system.debug(unitMap);
            for(OfferLines__c ofl :[SELECT Id,Name,OfferOn__c,OfferType__c,OfferValue__c,VoucherName__c, OfferName__c FROM OfferLines__c WHERE OfferName__c in :offerLineMap.KeySet()]){
                offerLineMap.get(ofl.OfferName__c).add(ofl);
            }
            if(!unitMap.isEmpty()){
                for(MemoCalculationInput inputParam : memoCalculationInput){
                    MemoCalculationWrapper calculationWrapper    = inputParam.calculationWrapper;
                    MemoCalculationWrapper calculationWrapperObj = new MemoCalculationWrapper();
                    
                    if(calculationWrapper!=null && inputParam.offerChanged ==false){
                        calculationWrapperObj.unitId=inputParam.unitId;
                        calculationWrapperObj.discountPercentage=calculationWrapper.discountPercentage;
                        calculationWrapperObj.rebatePercentage=calculationWrapper.rebatePercentage;
                        calculationWrapperObj.scWaiverYears=calculationWrapper.scWaiverYears;
                        calculationWrapperObj.pmFeeYear=calculationWrapper.pmFeeYear;
                        calculationWrapperObj.homeMaintenanceYears=calculationWrapper.homeMaintenanceYears;
                        calculationWrapperObj.ADMFeePercentage=calculationWrapper.ADMFeePercentage;
                        calculationWrapperObj.subsidyPercentage=calculationWrapper.subsidyPercentage;
                        calculationWrapperObj.internalCommissionPercentage=calculationWrapper.internalCommissionPercentage;
                        calculationWrapperObj.brokerCommissionPercentage=calculationWrapper.brokerCommissionPercentage;
                        calculationWrapperObj.selectedVoucher=calculationWrapper.selectedVoucher;
                        calculationWrapperObj.selectedMembership=calculationWrapper.selectedMembership;
                        calculationWrapperObj.isInit=calculationWrapper.isInit;
                        if(calculationWrapper.isInit == true ){
                            calculationWrapperObj.internalCommissionPercentage = opRecord.BrokerAgencyAccount__c !=null ? Decimal.ValueOf(Utilities.getConstant('MemoDirectCommissionWithBroker').ConstantValue__c) : Decimal.ValueOf(Utilities.getConstant('MemoDirectCommissionWithoutBroker').ConstantValue__c); 
                        }
                        
                       
                    }else if(inputParam.offerID!=null && inputParam.offerChanged == true){
                            calculationWrapperObj.unitId=inputParam.unitId;
                            calculationWrapperObj.discountPercentage=0;
                            calculationWrapperObj.rebatePercentage=0;
                            calculationWrapperObj.scWaiverYears=0;
                            calculationWrapperObj.pmFeeYear=0;
                            calculationWrapperObj.homeMaintenanceYears=0;
                            calculationWrapperObj.ADMFeePercentage=0;
                            calculationWrapperObj.subsidyPercentage=0;
                            //calculationWrapperObj.internalCommissionPercentage=0;
                            //calculationWrapperObj.brokerCommissionPercentage=0;
                        
                        for( OfferLines__c offerLine : offerLineMap.get(inputParam.offerID)){
                            if (offerLine.OfferOn__c == Constants.OFFER_ON_HOME_MAINTENNANCE_FEE) {
                                calculationWrapperObj.homeMaintenanceYears = offerLine.OfferValue__c;
                            }
                            else if (offerLine.OfferOn__c == COnstants.OFFER_ON_ADM_FEE) {
                                calculationWrapperObj.ADMFeePercentage = offerLine.OfferValue__c;
                            }
                            else if (offerLine.OfferOn__c == Constants.OFFER_ON_PM_FEE) {
                                calculationWrapperObj.pmFeeYear = offerLine.OfferValue__c;
                            }
                            else if (offerLine.OfferOn__c == Constants.OFFER_ON_SERVICE_CHARGES) {
                                calculationWrapperObj.scWaiverYears = offerLine.OfferValue__c;
                            }
                            else if (offerLine.OfferType__c == Constants.OFFER_TYPE_REBATE) {
                                calculationWrapperObj.rebatePercentage = offerLine.OfferValue__c;
                            }
                        }
                    }
                    set<String> voucherCombo = new set<String>();
                    set<String> membershipCombo = new set<String>();
    
                    list<map<String,string>> voucherOptions = new list<map<String,string>>(); 
                    list<map<String,string>> membershipOptions  = new list<map<String,string>>(); 
                    map<id,Decimal> offerValuesMap = new map<id,Decimal>();
                    for(OfferLines__c ofl : activeOfferLines){
                        if(ofl.VoucherName__c!=null && ofl.OfferValue__c!=null){
                            if(ofl.OfferOn__c == Constants.OFFER_ON_MEMBERSHIP){
                                if(  !membershipCombo.contains(ofl.VoucherName__c+''+ofl.OfferValue__c)){
                                    membershipOptions.add(new map<string,string>{'label' =>ofl.VoucherName__c + ' ('+String.ValueOf(ofl.OfferValue__c)+')', 'value' =>ofl.Id /*String.ValueOf(ofl.OfferValue__c) */ });
                                    offerValuesMap.put(ofl.Id, ofl.OfferValue__c.setScale(2));
                                }
                                membershipCombo.add(ofl.VoucherName__c+''+ofl.OfferValue__c);
                            }else{
                                if(!voucherCombo.contains(ofl.VoucherName__c+''+ofl.OfferValue__c)){
                                    voucherOptions.add(new map<string,string>{'label' =>ofl.VoucherName__c + ' ('+String.ValueOf(ofl.OfferValue__c)+')' , 'value' =>ofl.Id  /*String.ValueOf(ofl.OfferValue__c)*/ });
                                    offerValuesMap.put(ofl.Id, ofl.OfferValue__c.setScale(2));
                                }
                                voucherCombo.add(ofl.VoucherName__c+''+ofl.OfferValue__c);
                            }
                        }
                        
                    }
                    calculationWrapperObj.calculate( unitMap.get(inputParam.unitId) ,voucherOptions,membershipOptions);
                    calculationWrapperObj.voucherValue = (calculationWrapperObj.selectedVoucher!='' && calculationWrapperObj.selectedVoucher!=null && offerValuesMap.containsKey(calculationWrapperObj.selectedVoucher)) ? offerValuesMap.get(calculationWrapperObj.selectedVoucher):0;
                    calculationWrapperObj.membershipValue = (calculationWrapperObj.selectedMembership!='' && calculationWrapperObj.selectedMembership!=null && offerValuesMap.containsKey(calculationWrapperObj.selectedMembership) ) ? offerValuesMap.get(calculationWrapperObj.selectedMembership):0;
                    retrunObject.add(calculationWrapperObj);
                }
                
            }
            
            //Response setting
            handler.response.success = true;
            handler.response.data = retrunObject;
            handler.finalize();
            
        } catch (Exception e) {
            System.debug('msg '+ e.getMessage());
            System.debug('line no '+e.getLineNumber());
             //Response setting
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
            
        }
    }
    
    global class MemoCalculationInput {
        public String unitId                                {get; Set;}
        public String offerID                               {get; Set;}
        public boolean offerChanged                         {get; set;}
        public String paymentPlanId                         {get; Set;}
        public MemoCalculationWrapper calculationWrapper    {get; set;}
        public MemoCalculationInput(){}
        
    }

    global class MemoCalculationWrapper {
            //public list<map<String,string>>  memoTypes {get;set;}
            public String unitId                                {get; Set;}
            public boolean isInit {get; set;}
            
           
            public decimal discountPercentage  {get; set;}
            public decimal discountAmount   {get; set;}
            public string discountValidation    {get; set;}
            public decimal discountLowerBound   {get; set;}
            public decimal discountUpperBound   {get; set;}

            public decimal rebatePercentage     {get; set;}
            public decimal rebateValue          {get; set;}
            public string rebateValidation      {get; set;}
            public decimal rebateLowerBound     {get; set;}
            public decimal rebateUpperBound     {get; set;}

            public decimal scWaiverYears        {get; set;}
            public decimal scWaiverValue        {get; set;}
            public string scWaiverValidation    {get; set;}
            public decimal scWaiverLowerBound   {get; set;}
            public decimal scWaiverUpperBound   {get; set;}

            public decimal pmFeeYear            {get; set;}
            public decimal pmFeeValue           {get; set;}
            public string pmFeeValidation       {get; set;}
            public decimal pmFeeLowerBound      {get; set;}
            public decimal pmFeeUpperBound      {get; set;}

            public decimal homeMaintenanceYears {get; set;}
            public decimal homeMaintenanceValue {get; set;}
            public string homeMaintenanceValidation     {get; set;}
            public decimal homeMaintenanceLowerBound    {get; set;}
            public decimal homeMaintenanceUpperBound    {get; set;}

            public decimal ADMFeePercentage             {get; set;}
            public decimal ADMFeeValue                  {get; set;}
            public string ADMFeeValidation              {get; set;}
            public decimal ADMFeeLowerBound             {get; set;}
            public decimal ADMFeeUpperBound             {get; set;}

            public decimal internalCommissionPercentage {get; set;}
            public decimal internalCommissionValue      {get; set;}
            public string internalCommissionValidation  {get; set;}
            public decimal internalCommissionLowerBound {get; set;}
            public decimal internalCommissionUpperBound {get; set;}

            public decimal brokerCommissionPercentage   {get; set;}
            public decimal brokerCommissionValue        {get; set;}
            public string brokerCommissionValidation    {get; set;}
            public decimal brokerCommissionLowerBound   {get; set;}
            public decimal brokerCommissionUpperBound   {get; set;}

            public decimal subsidyPercentage            {get; set;}
            public decimal subsidyValue                 {get; set;}
            public string subsidyValidation             {get; set;}
            public decimal subsidyLowerBound            {get; set;}
            public decimal subsidyUpperBound            {get; set;}

            public string selectedVoucher               {get; set;}
            public decimal voucherValue                 {get; set;}
            public list<map<String,string>> voucherOptions  {get; set;}

            public string selectedMembership                {get; set;}
            public decimal membershipValue                     {get; set;}
            public list<map<String,string>> membershipOptions   {get; set;}

            public decimal netImpactPercentage                  {get; set;}
            public decimal netImpactValue                   {get; set;}
            public string netImpactValidation               {get; set;}
            public boolean isValid                  {get;set;}

            public MemoCalculationWrapper(){
                //memoTypes = new list<map<String,string>>();
                isInit = false;
                discountPercentage  = 0;
                discountAmount =0;
                discountValidation  ='';
                discountLowerBound =0;
                discountUpperBound =100;

                rebatePercentage   = 0;
                rebateValue        = 0;
                rebateValidation    ='';
                rebateLowerBound   =0;
                rebateUpperBound   =100;

                scWaiverYears      = 0;
                scWaiverValue      = 0;
                scWaiverValidation  ='';
                scWaiverLowerBound =0;
                scWaiverUpperBound =10;

                pmFeeYear          = 0;
                pmFeeValue         = 0;
                pmFeeValidation     ='';
                pmFeeLowerBound    =0;
                pmFeeUpperBound    =10;

                homeMaintenanceYears = 0;
                homeMaintenanceValue = 0;
                homeMaintenanceValidation   ='';
                homeMaintenanceLowerBound  =0;
                homeMaintenanceUpperBound  =10;

                ADMFeePercentage         = 0;  
                ADMFeeValue                = 0;
                ADMFeeValidation            ='';
                ADMFeeLowerBound           =0;
                ADMFeeUpperBound          =2; 

                internalCommissionPercentage = 0.5;
                internalCommissionValue    = 0;
                internalCommissionValidation='';
                internalCommissionLowerBound =0;
                internalCommissionUpperBound = Decimal.valueOf(System.label.MemoDirectCommission);

                brokerCommissionPercentage  = 0;
                brokerCommissionValue       = 0;
                brokerCommissionValidation  ='';
                brokerCommissionLowerBound  =0;
                brokerCommissionUpperBound = Decimal.valueOf(System.label.MemoIndirectCommission);

                subsidyPercentage           = 0;
                subsidyValue               = 0;
                subsidyValidation           ='';
                subsidyLowerBound          =0;
                subsidyUpperBound          =100;

                selectedVoucher    ='';         
                voucherValue       =0;        
                voucherOptions = new list<map<String,string>>(); 
            
                selectedMembership               ='';      
                membershipValue                   =0;       
                membershipOptions  = new list<map<String,string>>(); 

                netImpactPercentage                = 0;
                netImpactValue                 = 0;
                netImpactValidation             ='';

                isValid=false;
            }


            public void calculate(Unit__c unitRec, list<map<String,string>> voucherValues, list<map<String,string>> membershipValues){

                discountAmount = discountPercentage!=null? (discountPercentage * unitRec.SellingPrice__c /100).setScale(2) : 0;
                discountValidation  = (discountPercentage!=null && (discountPercentage < discountLowerBound || discountPercentage > discountUpperBound )) ? 'Please enter valid value':'';
                decimal dicountedValue = unitRec.SellingPrice__c - discountAmount;

                rebateValue        = rebatePercentage!=null? (rebatePercentage * unitRec.SellingPrice__c/100).setScale(2) : 0;
                rebateValidation    = (rebatePercentage!=null && (rebatePercentage < rebateLowerBound || rebatePercentage > rebateUpperBound )) ? 'Please enter valid value':'';
                
                decimal areaVal = unitRec.MeasuredArea__c!=null && unitRec.MeasuredArea__c!=0 ? unitRec.MeasuredArea__c : unitRec.SaleableArea__c;
                scWaiverValue      = (scWaiverYears!=null && areaVal !=null && unitRec.AnticipatedServiceCharges__c !=null ) ? (scWaiverYears * areaVal *unitRec.AnticipatedServiceCharges__c).setScale(2) : 0;
                scWaiverValidation  =(scWaiverYears!=null && (scWaiverYears < scWaiverLowerBound || scWaiverYears > scWaiverUpperBound )) ? 'Please enter valid value':'';
                
                pmFeeValue         = (pmFeeYear!=null &&  unitRec.BuildingSectionName__r.PropertyManagementFee__c!= null && unitRec.MarketLeaseRent__c!=null ) ? ((unitRec.BuildingSectionName__r.PropertyManagementFee__c/100) * unitRec.MarketLeaseRent__c * pmFeeYear ).setScale(2)  : 0;
                pmFeeValidation     =(pmFeeYear!=null && (pmFeeYear < pmFeeLowerBound || pmFeeYear > pmFeeUpperBound )) ? 'Please enter valid value':'';
                
                homeMaintenanceValue = (homeMaintenanceYears!=null && unitRec.BuildingSectionName__r.HomeMaintenanceFee__c!=null)? (homeMaintenanceYears * unitRec.BuildingSectionName__r.HomeMaintenanceFee__c).setScale(2) : 0;
                homeMaintenanceValidation  = (homeMaintenanceYears!=null && (homeMaintenanceYears < homeMaintenanceLowerBound || homeMaintenanceYears > homeMaintenanceUpperBound )) ? 'Please enter valid value':'';
                
                ADMFeeValue              = ADMFeePercentage!=null? (ADMFeePercentage * unitRec.SellingPrice__c/100).setScale(2) : 0;
                ADMFeeValidation        =   (ADMFeePercentage!=null && (ADMFeePercentage < ADMFeeLowerBound || ADMFeePercentage > ADMFeeUpperBound )) ? 'Please enter valid value':'';
                
                internalCommissionValue    = internalCommissionPercentage!=null? (internalCommissionPercentage * dicountedValue/100).setScale(2) : 0;
                internalCommissionValidation= (internalCommissionPercentage!=null && (internalCommissionPercentage <internalCommissionLowerBound || internalCommissionPercentage > internalCommissionUpperBound )) ? 'Please enter valid value':'';
                
                brokerCommissionValue      = brokerCommissionPercentage!=null? (brokerCommissionPercentage * dicountedValue/100).setScale(2) : 0;
                brokerCommissionValidation = (brokerCommissionPercentage!=null && (brokerCommissionPercentage < brokerCommissionLowerBound || brokerCommissionPercentage > brokerCommissionUpperBound )) ? 'Please enter valid value':'';
                
                subsidyValue               = subsidyPercentage!=null? (subsidyPercentage/100 * (unitRec.SellingPrice__c*0.8)).setScale(2) : 0;
                subsidyValidation        =   (subsidyPercentage!=null && (subsidyPercentage < subsidyLowerBound || subsidyPercentage > subsidyUpperBound )) ? 'Please enter valid value':'';
                
                //selectedVoucher    ='';         
                //voucherValue       =0;        
                voucherOptions = voucherValues; 
            
                //selectedMembership               ='';      
                //membershipValue                   =0;    
                membershipOptions  = membershipValues; 

               
                netImpactValue                 =  (discountAmount + rebateValue +scWaiverValue + pmFeeValue + ADMFeeValue +internalCommissionValue+brokerCommissionValue+subsidyPercentage + voucherValue + membershipValue).setScale(2) ;
                netImpactPercentage = ((netImpactValue/unitRec.SellingPrice__c ) *100 ).setScale(2);
                netImpactValidation             = (netImpactPercentage >50 || netImpactPercentage ==0) ?'Summation for all percentage fields should be more than 0% and less than 50%':'';

                isValid = (isInit!=null && isInit) || (discountValidation=='' && rebateValidation=='' &&  scWaiverValidation=='' && pmFeeValidation=='' && homeMaintenanceValidation=='' && ADMFeeValidation =='' && internalCommissionValidation == '' && brokerCommissionValidation=='' && netImpactValidation=='');
            }
    }
}