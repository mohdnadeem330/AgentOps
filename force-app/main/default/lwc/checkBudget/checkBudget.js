import { LightningElement, wire, track, api } from "lwc";
import { CurrentPageReference } from 'lightning/navigation';
import getUnitQuery from "@salesforce/apex/UnitService.getUnitQuery";
import getBudgetLinesQuery from "@salesforce/apex/BudgetLinesService.getBudgetLinesQuery";
import {loadStyle} from 'lightning/platformResourceLoader'
import DataTableColors from '@salesforce/resourceUrl/DataTableColors'

import getAvailableProjectBudgetJSON from "@salesforce/apex/BudgetLinesService.getAvailableProjectBudgetJSON";

const saleBudgetCategorycolumns = [
    { label: 'Budget Defined', fieldName: 'TotalBudget', fixedWidth: 150, wrapText: true, cellAttributes:{
        class:{fieldName:'yellowColor'}
    }}
];
const saleTotalBudgetcolumns = [
    { label: 'Budget Utilized', fieldName: 'BudgetUtilized', fixedWidth: 150, wrapText: true, cellAttributes:{
        class:{fieldName:'blueColor'}
    }}
];
const saleBudgetAvailablecolumns = [
    { label: 'Available Budget', fieldName: 'BudgetAvailable', fixedWidth: 150, wrapText: true, cellAttributes:{
        class:{fieldName:'redColor'}
    }}
];


const discountBudgetCategorycolumns = [
    { label: 'Budget Defined', fieldName: 'TotalBudget', fixedWidth: 130, wrapText: true, cellAttributes:{
        class:{fieldName:'yellowColor'}
    }}
];
const discountTotalBudgetcolumns = [
    { label: 'Budget Utilized', fieldName: 'BudgetUtilized', fixedWidth: 130, wrapText: true, cellAttributes:{
        class:{fieldName:'blueColor'}
    }}
];
const discountBudgetAvailablecolumns = [
    { label: 'Available Budget', fieldName: 'BudgetAvailable', fixedWidth: 130, wrapText: true, cellAttributes:{
        class:{fieldName:'redColor'}
    }}
];


export default class CheckBudget extends LightningElement {
    saleBudgetCategorycolumns = saleBudgetCategorycolumns;
    saleTotalBudgetcolumns = saleTotalBudgetcolumns;
    saleBudgetAvailablecolumns = saleBudgetAvailablecolumns;
    discountBudgetCategorycolumns = discountBudgetCategorycolumns;
    discountTotalBudgetcolumns = discountTotalBudgetcolumns;
    discountBudgetAvailablecolumns = discountBudgetAvailablecolumns;

    @api openModal = false;
    @track budgetLinesSaleData;
    @track budgetLinesDiscountData;
    @track unitName;
    currentPageReference = null; 
    urlStateParameters = null;
    isCssLoaded = false
    unitFieldValue;

    projectBudgetIds;
    availableProjectBudget;
@api projectBudgetId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
            this.urlStateParameters = currentPageReference.attributes.recordId;
            this.unitFieldValue = this.urlStateParameters || null;
       }
    }

    OpenModal(){
        this.openModal = true;
    }

    closeModal2() {
       
        this.openModal = false;
    }

    @api invoke() {
        this.OpenModal () || 0;
    }

    async prepareData() {
        let newDiscountTableData = [];
        let newSaleTableData = [];

        let unitQuery = 'select ProjectBudget__c,Name from Unit__c where Id = \''+ this.unitFieldValue +'\' limit 1';
        const unitNewData = await getUnitQuery({query:unitQuery});
        this.unitName = 'Budget Details (' + unitNewData[0].Name +')' ;
        let budgetLinesQuery = 'select BudgetCategory__c,Name,TotalBudget__c,ERPBudgetUtilized__c,ERPBudgetCommitment__c,BudgetAvailable__c,ERPBudgetAvailable__c from BudgetLines__c where ProjectName__c = \''+ unitNewData[0].ProjectBudget__c +'\'';
        const budgetLinesNewData = await getBudgetLinesQuery({query:budgetLinesQuery});
        budgetLinesNewData.forEach(record => {
            record.TotalBudget = record.TotalBudget__c + '\n' +  record.Name;
            record.BudgetAvailable = record.BudgetAvailable__c + '\n' +  record.Name;
            record.BudgetUtilized = record.ERPBudgetUtilized__c + '\n' +  record.Name;
            record.yellowColor = 'datatableCss-yellow' ;
            record.blueColor = 'datatableCss-blue' ;
            record.redColor = 'datatableCss-green' ;


        });
        for (let i = 0; i < budgetLinesNewData.length; i++) {
            if (budgetLinesNewData[i].BudgetCategory__c == 'Discount Bucket') {
                newDiscountTableData.push(budgetLinesNewData[i]);
            }else{
                newSaleTableData.push(budgetLinesNewData[i]);
            }
        }
        this.budgetLinesSaleData = newSaleTableData;
        this.budgetLinesDiscountData = newDiscountTableData;
        console.log(this.budgetLinesSaleData);
        console.log(this.budgetLinesDiscountData);

    }


     @track availableBudgetList=[];
     @track totalBudgetList=[];
     @track utliziedList=[];
     @track allLists=[];

     @track discountAndRebatesAvailableBudgetList=[];
     @track discountAndRebatesTotalBudgetList=[];
     @track discountAndRebatesUtliziedList=[];
     @track allDiscountAndRebatesLists=[];

     labels=["Internal Commission","External Commission","ADM Waiver Fee","SC Waiver","Other Sales Support",
     "Home Maintenance","Darna Loyalty","Payment Provisions","Mortgage Subsidy","Forfeited  Cash","Total Sum"];

     summaryLabels=["Discount","Rebate","Total Sum"];



     addLabels(){

        this.availableBudgetList=this.labels.map((item)=>{return {fieldName:item, value:""}   });
        this.availableBudgetList=[...this.availableBudgetList];

        console.log(JSON.stringify(this.availableBudgetList));
        this.totalBudgetList=this.labels.map((item)=>{return {fieldName:item, value:""}   });
        this.totalBudgetList=[...this.totalBudgetList];


        this.utliziedList=this.labels.map((item)=>{return {fieldName:item, value:""}   });
        this.utliziedList=[...this.utliziedList];


        this.discountAndRebatesAvailableBudgetList=this.summaryLabels.map((item)=>{return {fieldName:item, value:0}   });
        this.discountAndRebatesAvailableBudgetList=[...this.discountAndRebatesAvailableBudgetList];

        this.discountAndRebatesTotalBudgetList=this.summaryLabels.map((item)=>{return {fieldName:item, value:0}   });
        this.discountAndRebatesTotalBudgetList=[...this.discountAndRebatesTotalBudgetList];

        this.discountAndRebatesUtliziedList=this.summaryLabels.map((item)=>{return {fieldName:item, value:0}   });
        this.discountAndRebatesUtliziedList=[...this.discountAndRebatesUtliziedList];
     }

    async getAvailableProjectBudget(){

        this.addLabels () || 0;


       


       
        let parameterToSend;
        if(this.projectBudgetId == "" || this.projectBudgetId == null || this.projectBudgetId == undefined){
        let unitQuery = 'select ProjectBudget__c,Name from Unit__c where Id = \''+ this.unitFieldValue +'\' limit 1';
        const unitNewData = await getUnitQuery({query:unitQuery});
         parameterToSend=unitNewData[0].ProjectBudget__c;
      
         
        }else{
            parameterToSend=this.projectBudgetId;

           
        }
        console.log("-------------2----------------");
        console.log(parameterToSend);
        console.log("----------------------------");
        
        getAvailableProjectBudgetJSON({projectBudgetId:parameterToSend}).
        then((response )=>{
//?.toLocaleString() will ,
    
// console.log("-------------response----------------");
// console.log(JSON.stringify(response));
// console.log("----------------------------");


console.log("-------------response----------------");
console.log(Object.assign({},response));
console.log("----------------------------");
this.availableBudgetList[0].value=response.availableinternalCommissionAmount?.toLocaleString () || 0;
this.availableBudgetList[1].value=response.availableexternalCommissionAmount?.toLocaleString() || 0;
this.availableBudgetList[2].value=response.availableADMWaiverFee?.toLocaleString() || 0;
this.availableBudgetList[3].value=response.availableSCWaiverAmount?.toLocaleString() || 0;
this.availableBudgetList[4].value=response.availableotherSalesSupportAmount?.toLocaleString () || 0;
this.availableBudgetList[5].value=response.availablehomeMaintenanceWaiverFee?.toLocaleString () || 0;
this.availableBudgetList[6].value=response.availabledarnaLoyalty ?.toLocaleString () || 0;
this.availableBudgetList[7].value=response.availablePaymentProvisionAmount ?.toLocaleString () || 0;
this.availableBudgetList[8].value=response.availablemortgageSubsidy?.toLocaleString () || 0;
this.availableBudgetList[9].value=response.availableForfeitedAmount?.toLocaleString () || 0;
this.availableBudgetList[10].value=response.availableSalesSupportBucket?.toLocaleString () || 0;
this.availableBudgetList=[...this.availableBudgetList];



this.totalBudgetList[0].value=response.totalinternalCommissionAmount?.toLocaleString () || 0;
this.totalBudgetList[1].value=response.totalexternalCommissionAmount?.toLocaleString () || 0;
this.totalBudgetList[2].value=response.totalADMWaiverFee?.toLocaleString () || 0;
this.totalBudgetList[3].value=response.totalSCWaiverAmount?.toLocaleString () || 0;
this.totalBudgetList[4].value=response.totalotherSalesSupportAmount?.toLocaleString () || 0;
this.totalBudgetList[5].value=response.totalhomeMaintenanceWaiverFee?.toLocaleString () || 0;
this.totalBudgetList[6].value=response.totaldarnaLoyalty?.toLocaleString () || 0;
this.totalBudgetList[7].value=response.totalPaymentProvisionAmount?.toLocaleString () || 0;
this.totalBudgetList[8].value=response.totalmortgageSubsidy?.toLocaleString () || 0;
this.totalBudgetList[9].value=response.totalForfeitedAmount?.toLocaleString () || 0;
this.totalBudgetList[10].value=response.totalSalesSupportBucket?.toLocaleString () || 0;
this.totalBudgetList=[...this.totalBudgetList];



this.utliziedList[0].value=response.internalCommissionAmount?.toLocaleString () || 0;
this.utliziedList[1].value=response.externalCommissionAmount?.toLocaleString () || 0;
this.utliziedList[2].value=response.ADMWaiverFee?.toLocaleString () || 0;
this.utliziedList[3].value=response.SCWaiverAmount?.toLocaleString () || 0;
this.utliziedList[4].value=response.otherSalesSupportAmount?.toLocaleString () || 0;
this.utliziedList[5].value=response.homeMaintenanceWaiverFee?.toLocaleString () || 0;
this.utliziedList[6].value=response.darnaLoyalty?.toLocaleString () || 0;
this.utliziedList[7].value=response.utilizedPaymentProvisionAmount?.toLocaleString () || 0;
this.utliziedList[8].value=response.mortgageSubsidy?.toLocaleString () || 0;
this.utliziedList[9].value=response.utilizedForfeitedAmount?.toLocaleString () || 0; 
this.utliziedList[10].value=response.utilizedSalesSupportBucket?.toLocaleString () || 0;
this.utliziedList=[...this.utliziedList];



this.allLists.push({ class:"custom-card white-yellow-bg",title:"BUDGET DEFINED" , items:this.totalBudgetList});
this.allLists.push({ class:"custom-card white-blue-bg",title:"BUDGET UTILIZED",items:this.utliziedList});
this.allLists.push({class:"custom-card white-green-bg",title:"AVAILABLE BUDGET" , items:this.availableBudgetList } );

this.allLists=[...this.allLists];



console.log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");


this.allLists.forEach((item)=>{
    console.log(JSON.stringify(item.items));
});
console.log("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");



this.discountAndRebatesTotalBudgetList[0].value=response.totaldiscountAmount?.toLocaleString () || 0;
this.discountAndRebatesTotalBudgetList[1].value=response.totalRebateAmount?.toLocaleString () || 0;
this.discountAndRebatesTotalBudgetList[2].value=response.totalDiscountandRebateBucket?.toLocaleString () || 0;
this.discountAndRebatesTotalBudgetList=[...this.discountAndRebatesTotalBudgetList];


// console.log("--------------1-------------------");
// console.log(JSON.stringify());
// console.log("--------------1-------------------");
this.discountAndRebatesUtliziedList[0].value=response.discountAmount?.toLocaleString () || 0;
this.discountAndRebatesUtliziedList[1].value=response.rebateAmount?.toLocaleString () || 0;
this.discountAndRebatesUtliziedList[2].value=response.utilizedDiscountandRebateBucket?.toLocaleString () || 0;
this.discountAndRebatesUtliziedList=[...this.discountAndRebatesUtliziedList];



this.discountAndRebatesAvailableBudgetList[0].value=response.availablediscountAmount?.toLocaleString () || 0;
this.discountAndRebatesAvailableBudgetList[1].value=response.availablerebateAmount?.toLocaleString () || 0;
this.discountAndRebatesAvailableBudgetList[2].value=response.availableDiscountandRebateBucket?.toLocaleString () || 0;
this.discountAndRebatesAvailableBudgetList=[...this.discountAndRebatesAvailableBudgetList];


this.allDiscountAndRebatesLists.push({ class:"custom-card white-yellow-bg",title:"BUDGET DEFINED" , items:this.discountAndRebatesTotalBudgetList});
this.allDiscountAndRebatesLists.push({ class:"custom-card white-blue-bg",title:"BUDGET UTILIZED",items:this.discountAndRebatesUtliziedList});
this.allDiscountAndRebatesLists.push({class:"custom-card white-green-bg",title:"AVAILABLE BUDGET" , items:this.discountAndRebatesAvailableBudgetList } );



this.allDiscountAndRebatesLists=[...this.allDiscountAndRebatesLists];

        
        }).catch(error2=>{
            console.error("--------------Errorrrrrr-------------------");
            console.error(error2);
            console.error("--------------Errorrrrrr-------------------");
        });
    }




    async connectedCallback() {
       
        //this.prepareData () || 0;

        this.getAvailableProjectBudget () || 0;
    }


    closeModal(){
        this.openModal=false;
        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
    }

    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, DataTableColors).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the colors")
        })
    }
}