import { LightningElement } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getInvoiceBundles from '@salesforce/apex/InvoiceBundleController.getInvoiceBundles';
import cliSubmitForReview from '@salesforce/apex/InvoiceBundleController.cliSubmitForReview';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import BP_BANKDETAILS_NOTFOUND from '@salesforce/label/c.BP_BANKDETAILS_NOTFOUND';
const actions = [
    { label: 'Submit for Review', name: 'Submit_for_Review' }
]
const columns = [
    { label: 'Customer', fieldName: 'Customer', type: 'text' },
    { label: 'Agency Name', fieldName: 'AgencyName', type: 'text' },
    { label: 'Agent Name', fieldName: 'AgentName', type: 'text' },
    { label: 'Property', fieldName: 'Property', type: 'text' },
    { label: 'Unit Number', fieldName: 'UnitNumber', type: 'text' },
    { label: 'Net Price', fieldName: 'NetPrice', type: 'text' },
    { label: 'Order Date', fieldName: 'OrderDate', type: 'text' },
    { label: 'Commission', fieldName: 'Commission', type: 'text' },
    { label: 'Rate', fieldName: 'Rate', type: 'text' },
    { label: 'SalesOrder Status', fieldName: 'SalesOrderStatus', type: 'text' },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    /*{   label: '',
        type: 'action',
        initialWidth:'50px',
        typeAttributes: { rowActions: actions },
    },  */
]

export default class CommissionsBundleReport extends LightningElement {

    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";

    label = {BP_BANKDETAILS_NOTFOUND};

    tableData;
    propertyNameValues = [];
    unitValues = [];
    statusValues = [];
    filterStartDate ;
    filterEndDate ;
    showSpinner = false;
    invoiceBundleData = [];
    activeSections = [];
    columns = columns;
    openModal = false;
    ModalHeader;
    isLoading = false;
    mdl_Customer;
    mdl_AgencyName;
    mdl_AgentName;
    mdl_Property; 
    mdl_UnitNumber;
    mdl_NetPrice;
    mdl_OrderDate;
    mdl_Commission;
    mdl_Rate;
    mdl_Status;
    mdl_SalesOrderStatus;
    mdl_invoiceBundleId;
    mdl_commissionId;
    mdl_SubmitforReview = false;
    mdl_ReviewComments;
    mdl_disableSubmitForReview;
    isOpenManageInvoice = false;
    selectRowID;
    bankDetailsPresent;
    showPopUpActions=false;
    badgerBackgroundColor;
    missingBankDetails;
    vatMissingDetails; vatMissing = false;

    connectedCallback(){
        console.log('connectedCall Back');
        var todayDate = new Date();
        this.filterStartDate = todayDate.getFullYear() +'-1-1' ;
        this.filterEndDate = todayDate.getFullYear() +'-'+ (todayDate.getMonth() +1) +'-'+ todayDate.getDate() ;
        this.initCommissionRecords();
    }
    initCommissionRecords(){
    this.showSpinner = true;
    this.tableData = [];
        getInvoiceBundles({ startDate:   new Date(this.filterStartDate) , endDate:  new Date(this.filterEndDate) })
        .then(data => {
            console.log(JSON.stringify(data));
            this.invoiceBundleData = data;
            this.tableData = [...this.invoiceBundleData];

            let missingFields = data[0].InvoiceBundle.BankDetailsMissingFields__c;
            if(missingFields){
                missingFields.slice(-1) === ',' ? missingFields = missingFields.slice(0, -1) : '';
                this.missingBankDetails = 'Missing Bank Details: ' + missingFields;
            }

            let vatMissingFields = data[0].InvoiceBundle.VATDetailsMissing__c;
            if(vatMissingFields){
                this.vatMissing = true;
                vatMissingFields.slice(-1) === ',' ? vatMissingFields = vatMissingFields.slice(0, -1) : '';
                this.vatMissingDetails = 'Missing VAT Details: ' + vatMissingFields;
            }

            this.handleFilterChange();
            this.showSpinner = false;
            
        })
        .catch(error => {
            console.error(error);
            this.invoiceBundleData =undefined;
            this.showSpinner = false;
            this.tableData=undefined;
        });
    }
    clearFilter(){
        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        for(let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value='';
        }
        this.filterStartDate=undefined;
        this.filterEndDate=undefined;
        this.initCommissionRecords();
    }
    handleToggleSection(event){
      
    }
    handleRowAction(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('row data:::'+JSON.stringify(row));
        console.log(actionName+'__'+row);

        for(var i = 0; i<this.invoiceBundleData.length; i++){
            if(row.invoiceBundleId == this.invoiceBundleData[i].InvoiceBundle.Id){
                console.log('Invoice data::'+JSON.stringify(this.invoiceBundleData[i]));
                for(var j = 0; j<this.invoiceBundleData[i].commissionLineItems.length; j++){
                if(row.commissionId == this.invoiceBundleData[i].commissionLineItems[j].commissionId){
                    this.ModalHeader = this.invoiceBundleData[i].commissionLineItems[j].UnitNumber;
                    this.mdl_Customer = this.invoiceBundleData[i].commissionLineItems[j].Customer;
                    this.mdl_AgencyName = this.invoiceBundleData[i].commissionLineItems[j].AgencyName;
                    this.mdl_AgentName = this.invoiceBundleData[i].commissionLineItems[j].AgentName;
                    this.mdl_Property = this.invoiceBundleData[i].commissionLineItems[j].Property; 
                    this.mdl_UnitNumber = this.invoiceBundleData[i].commissionLineItems[j].UnitNumber;
                    this.mdl_NetPrice = this.invoiceBundleData[i].commissionLineItems[j].NetPrice;
                    this.mdl_OrderDate = this.invoiceBundleData[i].commissionLineItems[j].OrderDate;
                    this.mdl_Commission = this.invoiceBundleData[i].commissionLineItems[j].Commission;
                    this.mdl_Rate = this.invoiceBundleData[i].commissionLineItems[j].Rate;
                    this.mdl_Status = this.invoiceBundleData[i].commissionLineItems[j].Status;
                    this.mdl_SalesOrderStatus = this.invoiceBundleData[i].commissionLineItems[j].SalesOrderStatus;
                    this.mdl_invoiceBundleId = this.invoiceBundleData[i].commissionLineItems[j].invoiceBundleId;
                    this.mdl_commissionId = this.invoiceBundleData[i].commissionLineItems[j].commissionId;
                    this.mdl_SubmitforReview = this.invoiceBundleData[i].commissionLineItems[j].SubmitforReview;
                    this.mdl_ReviewComments = this.invoiceBundleData[i].commissionLineItems[j].ReviewComments;
                    this.mdl_disableSubmitForReview = (this.invoiceBundleData[i].commissionLineItems[j].disableSubmitForReview || this.invoiceBundleData[i].commissionLineItems[j].Status != 'Ready for Submission');
                }
            }
        }
        this.openModal = true;
    }

    }
    
    handleChange(event){
        if (event.target.name === 'SubmitForReview') {
            this.mdl_SubmitforReview = event.target.checked;
        }
        if(event.target.name === 'ReviewComments'){
            this.mdl_ReviewComments = event.target.value;
        }
    }
    submitForReview(){
        console.log('Submit for review');
        this.isLoading = true;
       cliSubmitForReview({mdl_commissionId : this.mdl_commissionId, mdl_ReviewComments : this.mdl_ReviewComments, mdl_SubmitforReview: this.mdl_SubmitforReview})
       .then(result => {
        this.isLoading = false;
        this.initCommissionRecords();
        this.openModal = false;
    }).catch(error => {
        console.log(error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            })
        );
        this.isLoading = false;
    })
    }
    closeReviewModal(){
        this.openModal = false; 
    }
    manageInvoice(event){
        this.isOpenManageInvoice = true;
        this.selectRowID = event.target.dataset.id;
        this.bankDetailsPresent = event.target.dataset.bankdetailspresent;
        let showPopUpActions = false;
        for(var i= 0; i < this.invoiceBundleData.length; i++){
            if(this.invoiceBundleData[i].CypherInvoiceBundleId == this.selectRowID){
                showPopUpActions = this.invoiceBundleData[i].enableActions;
            }
        }
        this.showPopUpActions = showPopUpActions;
    }
    closeModal(){
        this.isOpenManageInvoice = false;
        this.initCommissionRecords();
    }
    exportToCSV() { 
        let columnHeader = ["Customer","Agency Name", "Agent Name ", "Property", "Unit Number", "Net Price","Order Date","Comission","Rate",'Sales Order Status',"Status"];

        let jsonKeys = ["Customer","AgencyName","AgentName", "Property", "UnitNumber","NetPrice","OrderDate","Commission","Rate","SalesOrderStatus","Status"];
        var jsonRecordsData = [];
        for(var i = 0; i < this.invoiceBundleData.length; i++){
            for(var j=0; j<this.invoiceBundleData[i].commissionLineItems.length; j++){
                jsonRecordsData.push(this.invoiceBundleData[i].commissionLineItems[j]);
            } 
        }
        console.log('jsonRecordsData::'+jsonRecordsData);
        let csvIterativeData;  
        let csvSeperator ; 
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";  
        csvIterativeData = "";  
        csvIterativeData += columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  
        for (let i = 0; i < jsonRecordsData.length; i++) {  
          let counter = 0;  
          for (let iteratorObj in jsonKeys) {  
            let dataKey = jsonKeys[iteratorObj];  
            if (counter > 0) {  csvIterativeData += csvSeperator;  }  
            if (  jsonRecordsData[i][dataKey] !== null &&  
              jsonRecordsData[i][dataKey] !== undefined  
            ) { console.log(jsonRecordsData[i][dataKey]); 
                csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';  
            } else {  csvIterativeData += '""';  
            }  
            counter++;  
          }  
          csvIterativeData += newLineCharacter;  
        }  
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
        csvIterativeData = csvIterativeData.replace(' ', '_SPACE_');
        csvIterativeData = csvIterativeData.replace(/"/g, '');
        csvIterativeData = csvIterativeData.replace('_SPACE_',' ');
        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Commission Report.xls.csv';
        downloadLink.click();
    
    }
    handleFilerChnageWithDate(){
        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        var startDateForFilter ;
        var endDateForFilter ;
        for(let j = 0; j < allSearchFields.length; j++) {
            if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                
                if(allSearchFields[j].dataset.field == 'startDate' ){
                    startDateForFilter = allSearchFields[j].value ;
                }else if(allSearchFields[j].dataset.field == 'endDate'  ){
                    endDateForFilter = allSearchFields[j].value ;
                }

            }
        }
        console.log( '-- Handle the filter --' + this.startDateForFilter);
        console.log( '-- Handle the filter --' + this.endDateForFilter);
       
        if(startDateForFilter || endDateForFilter ){
            this.filterStartDate = startDateForFilter;
            this.filterEndDate = endDateForFilter;
            this.initCommissionRecords();
        }else{
            
            this.handleFilterChange();
        }
    }
    handleFilterChange(event){
        this.tableData = [];
        this.propertyNameValues = [];
        this.unitValues =[];
        this.statusValues = [];

        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        for(let i = 0; i < this.invoiceBundleData.length; i++) {
            var recordFiltered = false;
            for(let j = 0; j < allSearchFields.length; j++) {
                if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                    if(allSearchFields[j].dataset.field == 'Status__c'){
                    if(this.invoiceBundleData[i].InvoiceBundle[allSearchFields[j].dataset.field] != allSearchFields[j].value){
                        recordFiltered=true;
                        break;
                    }
                }
            }
            }
            if(!recordFiltered){
                if(this.statusValues.findIndex((item) => item.label === this.invoiceBundleData[i].InvoiceBundle.Status__c) === -1){
                    this.statusValues.push({ label: this.invoiceBundleData[i].InvoiceBundle.Status__c, value: this.invoiceBundleData[i].InvoiceBundle.Status__c });
                } 
                this.tableData.push(this.invoiceBundleData[i]);
            }
        }

        console.log('this.tableData::'+this.tableData);
        console.log('this.tableData length::'+this.tableData.length);
     }
 }