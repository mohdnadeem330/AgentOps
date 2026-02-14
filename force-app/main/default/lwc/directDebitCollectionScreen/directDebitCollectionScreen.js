import { LightningElement, wire, track  } from 'lwc';
import prepareDropdownData from "@salesforce/apex/DirectDebitCollectionController.prepareDropdownData";
import prepareLocationNames from "@salesforce/apex/BuildingSectionService.prepareLocationNames";
import getInstallmentLinesQuery from "@salesforce/apex/DirectDebitCollectionController.getInstallmentLinesQuery";
import createDirectDebitTransaction from "@salesforce/apex/DirectDebitCollectionController.createDirectDebitTransaction";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import CollectionThreshold from '@salesforce/label/c.CollectionThreshold';

const mainColumns = [
    
    { label: 'Sales Order', fieldName: 'linkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'salesOrderName' }, target: '_blank', tooltip: { fieldName: 'salesOrderName' }, sortable: "true" }},
   
    { label: 'Unit Number', fieldName: 'unitLinkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'unitNumber' }, target: '_blank', tooltip: { fieldName: 'unitNumber' }, sortable: "true" }},
   
    {label: 'Customer Name', fieldName: 'customerName', sortable: "true"},
    { label: 'Installment Date', fieldName: 'InstallmentDate__c', sortable: "true", type: "date-local", typeAttributes: {
        month: "2-digit",
        day: "2-digit"
    }},

    { label: 'Installment Amount', fieldName: 'InstallmentAmount__c', sortable: "true", type: 'currency',typeAttributes: { currencyCode: 'AED', step: '0.01' } },
    { label: 'Outstanding Amount', fieldName: 'OutstandingAmount__c', sortable: "true", type: 'currency',typeAttributes: { currencyCode: 'AED', step: '0.01' }  },
    { label: 'Applied Receipt Amount', fieldName: 'AmountReceived__c', sortable: "true", type: 'currency',typeAttributes: { currencyCode: 'AED', step: '0.01' }},
    { label: 'Collection Amount', fieldName: 'CollectionAmount', editable:'true',type: 'currency',typeAttributes: { currencyCode: 'AED', step: '0.01' },cellAttributes: {
    }},
    { label: 'Unallocated receipt amount', fieldName: 'unallocatedreceiptAmount',type: 'currency',typeAttributes: { currencyCode: 'AED', step: '0.01' },
    cellAttributes: { alignment: 'center' }},
    { label: 'Has Active Service Request', fieldName: 'hasServiceRequest',  sortable: "true" },

    { label: 'Installment Lines #', fieldName: 'installmentlinkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'installmentName' }, target: '_blank', tooltip: { fieldName: 'installmentName' }, sortable: "true" }},
    { label: 'Installment #', fieldName: 'InstallmentNumber__c', sortable: "true" },
    { label: 'Installment %', fieldName: 'InstallmentPercentage__c', sortable: "true" },
    /*{ label: 'Service Request', fieldName: 'serviceRequestId', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'serviceRequest' }, target: '_blank', tooltip: { fieldName: 'serviceRequest' }, sortable: "true" }}, */

    
    { label: 'Customer Bank Account Name', fieldName: 'CustomerBankAccountName', sortable: "true" },
    { label: 'Builing Name', fieldName: 'buildingName',   sortable: "true"  },
  
    
    { label: 'DDAR', fieldName: 'directDebitRequestlinkName', sortable: "true", type:'url', 
    typeAttributes:{label:{fieldName:'ddar' }, target:'_blank', tooltip:{fieldName:'ddar'}, sortable:'true'}},

    //{label: 'Unit Number', fieldName: 'unitNumber', sortable: "true"},
   
    //{ label: 'Installment Lines #', fieldName: 'Name', sortable: "true" },
    
    
   
    
    
    
   // { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' } }

    
];
export default class DirectDebitCollectionScreen extends LightningElement {

    projectNamePickListValues;
    locationNamePickListValues = [];
    @track columns = mainColumns;
    @track data;
    @track totalInstallments = 0;
    @track sortBy;
    @track sortDirection;
    @track pageNumber = 1;
    fldsItemValues = [];
    totalPages;
    rowsTableData = [];
    recordsToDisplay = []; 
    allSelectedRows = [];
    preselectedRows = [];
    selectedRowsPagesMap;
    unSelectedRowsPagesMap;
    selectedDatatableRows = [];
    isLoading=false;
    isLoadingModal = false;
    maturitydate;
    maturityStartDate;
    maturityEndDate;
    pageSize = 50;
    dataMap={};
    draftValueMap={};
    draftValueMapIds = [];
    finalInstallmentCollectionAmtMap ={};
    selection = [];
    errorIds = [];
    hasRowError = false;
    finalInstallmentCollectionIds = [];
    finalInstallmentCollectionCount = 0;
    isfinalInstallmentwarning = false;
    popupMessage = '';
    @track pageNumbershavingErrors = '';
    isInitiateCollections = false;
    hasSRforSelectedInstallmentLine = false;
    errors;
    _selected = [];
    selectedValues = [];
    holdingSelectedRowsObj={};
    @track disablesendForDD = true;
    @track isPagination = false;
    @track selectedSoInstallmentMap = new Map();
    @track mainColumnsMap = new Map();
    @track requiredOptions = ['Sales Order', 'Installment Lines #','Collection Amount'];
    @track selectedColumns = [];
    @track showFieldsToDisplay = false;
    @track collectionSent = false;
    @track exportData = [];
    @track enableExcel = false;
    onOpen = false;

    get options() {
        return [ 
            {label: 'Sales Order', value : 'Sales Order'},
            {label:'Has Active Service Request',value :'Has Active Service Request'},
            {label:'Customer Name',value :'Customer Name'},
            {label:'Customer Bank Account Name',value :'Customer Bank Account Name'},
            {label:'Builing Name',value :'Builing Name'},
            {label:'Unit Number',value :'Unit Number'},
            {label:'DDAR',value :'DDAR'},
            {label:'Installment Lines #',value :'Installment Lines #'},
            {label:'Installment #',value :'Installment #'},
            {label:'Installment %',value :'Installment %'},
            {label:'Installment Date',value :'Installment Date'},
            {label:'Installment Amount',value :'Installment Amount'},
            {label:'Outstanding Amount',value :'Outstanding Amount'},
            {label:'Applied Receipt Amount', value :'Applied Receipt Amount' },
            {label:'Collection Amount',value :'Collection Amount'},
            {label:'Unallocated receipt amount',value :'Unallocated receipt amount'}
            ];
    } 

    label = {
        CollectionThreshold
    };
    ddBankPickListValues = [
        {label: "None", value: 'None' },
        {label: "Abu Dhabi Commercial Bank", value: 'Abu Dhabi Commercial Bank' },
        {label: "First Abu Dhabi Bank", value: 'First Abu Dhabi Bank' }
    ];
    comboBoxOptions = [
        {label: "5", value: '5' },
        {label: "50", value: '50', selected:true},
        {label: "100", value: '100' },
        {label: "150", value: '150' }
    ];
   
    handleColumnSelection(){
        

        console.log('this.selectedColumns::'+this.selectedColumns);
        let selectedColumns = [];
        //this.requiredOptions = ['Sales Order', 'Installment Lines #','Collection Amount'];
        console.log('mainColumns:::'+JSON.stringify(mainColumns));
        for(var i=0; i<mainColumns.length; i++){
             this.mainColumnsMap.set(mainColumns[i].label, mainColumns[i]);
        }
       
        for(var i=0; i<this._selected.length; i++){
            console.log(this.mainColumnsMap.get(this._selected[i]));
            selectedColumns.push(this.mainColumnsMap.get(this._selected[i]));
        }
     this.columns = [...selectedColumns];
     //this._selected = [...this._selected];
     if(!selectedColumns.includes(this.mainColumnsMap.get(this._selected[i]))){
        this.selectedColumns.push(this.mainColumnsMap.get('Sales Order'));
        this.selectedColumns.push(this.mainColumnsMap.get('Installment Lines #'));
        this.selectedColumns.push(this.mainColumnsMap.get('Collection Amount'));
     }
     this.selectedColumns.push(this._selected[i]);
     this.showFieldsToDisplay =  false;
    }
    hideFieldModalBox(){
        this.showFieldsToDisplay =  false;
    }
    showFieldsToBedisplayed(){
        this.onOpen = true;
      let selectedColumns = [];
        console.log('this._selected::'+this._selected);
    if(this._selected.length>0){
    for(var i=0; i<this._selected.length; i++){
        selectedColumns.push(this._selected[i]); 
    }
   }
   this._selected = selectedColumns;
    console.log('this.selectedColumns::'+this.selectedColumns);
    this.showFieldsToDisplay =  true;
    }
    handleFieldsToDisplayChange(event){
        if(!this.onOpen) {
            this._selected = event.target.value;
            console.log('this._selected::'+this._selected);
        } else {
            this.onOpen = false;
            event.target.value = this._selected;
        }
        
    }
    handleResetColumnSelection(){
        this.columns =mainColumns;
        this.showFieldsToDisplay =  false;
    }
    handleValidation() {
     let projectNameField = this.template.querySelector(".projectNameField");
      if (!projectNameField.value) {
        projectNameField.setCustomValidity("Project must se selected to do successful search");
      } else {
         projectNameField.setCustomValidity(""); // clear previous value
        }
            projectNameField.reportValidity();
        }
        
    async handleSearchAll(event){
       console.log('this.columns ::'+this.columns );
        this.isLoading = true;
        this.data = [];
        
        this.dataMap={};
        this.totalInstallments = 0;
        this.recordsToDisplay = [];
        this.finalInstallmentCollectionAmtMap = {};
        this.finalInstallmentCollectionIds = [];
        this.holdingSelectedRowsObj={};
        this.errors = {};
        this.draftValueMapIds = [];
        this.draftValueMap={};
        this.errorIds = [];
        this.draftSelectedIds = [];
        this.finalInstallmentCollectionCount = 0;
        this.fldsItemValues = [];
        this.enableExcel = false;
        let projectNameField = this.template.querySelector('lightning-combobox');
       if (!projectNameField.value) {
                projectNameField.setCustomValidity("Project must be selected to do successful search");
                this.isLoading = false;
            } else {
                projectNameField.setCustomValidity(""); // clear previous value
               
            if( (this.maturityStartDate != undefined && (this.maturityEndDate == null || this.maturityEndDate == undefined)) || ( (this.maturityStartDate == null || this.maturityStartDate == undefined)  && this.maturityEndDate !=undefined)){
                const evt = new ShowToastEvent({
                    title: 'Installment Lines',
                    message: 'Start and End Dates are Mandatory to do successful search' ,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return false;
            }if(this.maturityStartDate > this.maturityEndDate){
                this.template.querySelector('.maturityStartDate').setCustomValidity("Installment Start date cannot be greater than Installment End Date");
                this.isLoading = false;
            }else{
                this.template.querySelector('.maturityStartDate').setCustomValidity("");
            }
            
        let newTableData = [];

        console.log('this.projectNameField::'+this.projectNameField);
        var condition = (this.projectNameField !== '' && this.projectNameField !== null && this.projectNameField !== undefined
        ? ' AND SalesOrder__r.ProjectName__c =\'' + this.projectNameField +'\'': '');
        
        condition += (this.buildingNameField !== '' && this.buildingNameField !== null && this.buildingNameField !== undefined
        ? (condition !== '' && condition !== null ? ' AND ' : '') +
          ' SalesOrder__r.UnitBuilding__c =\'' + this.buildingNameField +'\'': '');
        
          condition += (this.maturityEndDate !== '' && this.maturityEndDate !== null && this.maturityEndDate !== undefined &&
          this.maturityStartDate !== '' && this.maturityStartDate !== null && this.maturityStartDate !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
           ( ' InstallmentDate__c >=' + this.maturityStartDate +' AND '+ ' InstallmentDate__c <=' + this.maturityEndDate)+'':'');

     /*   condition += (this.maturitydate !== '' && this.maturitydate !== null && this.maturitydate !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' InstallmentDate__c =' + this.maturitydate +'':''); */

          var query; 
          if (condition !== '' || condition !== null || condition !== undefined ) {
            let salesOrderStatus = 'Sold';
            let receiptPaymentType = 'Direct Debit';
            let receiptStatus = 'Reversed';
            let installmentNumber = 1;
            let installPaymentStatus = 'Approved';
            //Added by Mahidhar ASF- 3621 added new field to query StopDefaultNotice__c
            query = 'SELECT SalesOrder__r.Directdebitauthorityreferencenumber__c,SalesOrder__r.Unit__r.BuildingSectionName__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Name,AmountReceived__c,SalesOrder__r.Unit__c,SalesOrder__r.Unit__r.Name,SalesOrder__r.Account__r.Name,ERPID__c,InstallmentAmount__c,InstallmentDateinArabic__c,InstallmentDate__c,InstallmentNumber__c,InstallmentPercentage__c,InvoicedAmount__c,InvoiceId__c,InvoiceNumber__c,Name,RevisedDate__c,SalesOrder__r.name,StatusIndicator__c,OutstandingAmount__c,StopDefaultNotice__c,(Select Id FROM Receipt_Allocations__r Where ReceiptAcknowledgement__r.PaymentType__c =\'' + receiptPaymentType +'\' AND ReceiptAcknowledgement__r.Status__c != \'' + receiptStatus +'\' ) FROM InstallmentLines__c WHERE SalesOrder__r.Directdebitauthorityreferencenumber__c != null ' +
          //  'AND (SalesOrder__r.Id = \''+ids+'\''+ 'OR SalesOrder__r.Id = \''+ids2+'\')'
            'AND SalesOrder__r.Status__c=\'' + salesOrderStatus +'\''+ ' AND PaymentInstallments__r.IsHandoverPayment__c = false AND InstallmentNumber__c != ' + installmentNumber + 
            ' AND PaymentInstallments__r.ApprovalStatus__c=\'' + installPaymentStatus +'\''+
            condition;
            console.log('query::'+query);
            const newData = await getInstallmentLinesQuery({query:query});

            newData.forEach(record => {
                record.installmentlinkName = '/'+record.installment.Id;
                record.installmentName = record.installment.Name
                record.linkName = '/'+record.installment.SalesOrder__r.Id;
                record.salesOrderName = record.installment.SalesOrder__r.Name;
                record.customerName = record.installment.SalesOrder__r.Account__r.Name;
                record.unitLinkName = '/'+record.installment.SalesOrder__r.Unit__r.Id;
                record.unitNumber = record.installment.SalesOrder__r.Unit__r.Name;
                record.buildinglinkname = '/'+record.installment.SalesOrder__r.Unit__r.BuildingSectionName__r.Id;
                record.buildingName = record.installment.SalesOrder__r.Unit__r.BuildingSectionName__r.Name;
                record.CollectionAmount = record.installment.AmountReceived__c != null? (record.installment.InstallmentAmount__c - record.installment.AmountReceived__c) : record.installment.InstallmentAmount__c;
                record.ddar = record.installment.SalesOrder__r.Directdebitauthorityreferencenumber__c; 
                record.InstallmentNumber__c = record.installment.InstallmentNumber__c; 
                record.InstallmentPercentage__c = record.installment.InstallmentPercentage__c;
                record.InstallmentDate__c = record.installment.InstallmentDate__c;
                record.InstallmentAmount__c = record.installment.InstallmentAmount__c;
                record.OutstandingAmount__c = record.installment.OutstandingAmount__c;
                record.AmountReceived__c = record.installment.AmountReceived__c;
                record.unallocatedreceiptAmount = record.UnallocatedReceiptAmount;
                record.CustomerBankAccountName = record.CustomerBankAccountName;
                record.Id = record.rowId;
                record.serviceRequest = record.serviceRequest != null ? record.serviceRequest : null;
                record.serviceRequestId = record.serviceRequestId != null? '/'+record.serviceRequestId: null;
                record.hasServiceRequest = record.hasServiceRequest;
                record.directDebitRequestlinkName =  '/'+record.directDebitRequest.Id;
               //ASF-3621
                record.StopDefaultNotice__c = record.installment.StopDefaultNotice__c;
                //record.ddarName = record.directDebitRequest.Name;
            });

            for (let i = 0; i < newData.length; i++) {
                //ASF-3416
                //Added by Mahidhar ASF- 3621
               if(newData[i].OutstandingAmount__c != 0 && (newData[i].StopDefaultNotice__c === false && newData[i].CollectionAmount > 10)){ 
                    newTableData.push(newData[i]);
                    this.dataMap[newData[i].rowId] = newData[i];
                }
               
            }
           if(newTableData.length > 0){
            this.enableExcel = true;
           }
            if (newTableData.length < 1 && !this.collectionSent)  {
                const evt = new ShowToastEvent({
                    title: 'Installment Lines',
                    message: 'No Installment Lines found' ,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
     if(this.collectionSent){
        this.collectionSent = false;
      }
            this.data = newTableData;
            this.totalInstallments = newTableData.length;
            this.pageSize = 50;
            this.paginationHelper();
        }
        this.isLoading = false;
    }
    projectNameField.reportValidity();
    }
    exportAsExcel(){
      console.log('export as Excel');
      let columnHeader = ["Sales Order", "Has Active Service Request", "Customer Name","Customer Bank Account Name", "Builing Name","Unit Number","DDAR","Installment Lines","Installment Number","Installment Percentage","Installment Date", "Installment Amount", "Outstanding Amount","Applied Receipt Amount","Collection Amount", "Unallocated receipt amount"]; 

      let jsonKeys = ["salesOrderName","hasServiceRequest", "customerName", "CustomerBankAccountName", "buildingName", "unitNumber","ddar","installmentName","InstallmentNumber__c","InstallmentPercentage__c", "InstallmentDate__c", "InstallmentAmount__c","OutstandingAmount__c", "AmountReceived__c", "CollectionAmount", "unallocatedreceiptAmount"];
      var jsonRecordsData = this.recordsToDisplay;  
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
            if (  jsonRecordsData[i][dataKey] !== null &&  jsonRecordsData[i][dataKey] !== undefined ) { 
                console.log(jsonRecordsData[i][dataKey]); 
                csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';  
            } else {  csvIterativeData += '""';  
            }  
            counter++;  
          }  
          csvIterativeData += newLineCharacter;  
        }  
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
        csvIterativeData = csvIterativeData.replace(' ', '_SPACE_');
        if(csvIterativeData.includes('#')){
         csvIterativeData = csvIterativeData.replaceAll('#', '');
        }
        csvIterativeData = csvIterativeData.replace(/"/g, '');
        csvIterativeData = csvIterativeData.replace('_SPACE_',' ');
        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Direct Debit Collection_'+this.projectNameField+'.xls.csv';
        downloadLink.click();
    }
    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    handleComboBoxChange(event){
     this.pageSize = event.target.value;
     this.paginationHelper();
    }
    handleChange(event) {
        console.log(event.target.name);
        console.log(event.target.value);
        this[event.target.name] = event.target.value;
    }
    handleMaturityDateChange(event){
        console.log('event.target.name::'+event.target.name);
        this[event.target.name] = event.target.value;
        this.maturitydate = event.target.value;
        if(event.target.name == 'maturityStartDate'){
           this.maturityStartDate = event.target.value;
        }
    if(event.target.name == 'maturityEnddate'){
       this.maturityEnddate = event.target.value;
    }
    }
    handleDDBankChange(event){
        this[event.target.name] = event.target.value;
    }
    async connectedCallback() {
      this.getDropDownData();
     }

    paginationHelper(event) {
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.totalInstallments / this.pageSize);
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
       for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalInstallments) {
                break;
            }
            this.recordsToDisplay.push(this.data[i]);
        }
        for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }  
            }
            if(this.hasRowError){
                break;
            }  
        }
        }
    
        if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
            this.disablesendForDD = false;
        }else{
            this.disablesendForDD = true;
        }
        
    }


    previousPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            }  else if(this.holdingSelectedRowsObj[this.pageNumber] != null) {
                this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } 
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
        this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
    }
    for(var i=0; i<=this.totalPages; i++){
        if(this.holdingSelectedRowsObj[i] != null){
           for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
             if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
              this.hasRowError = false;
             }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                this.hasRowError = false;
               }else{
                this.hasRowError = true;
                break;
             }
             
        }
        if(this.hasRowError){
            break;
        }
        
     }
    }

    if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
        this.disablesendForDD = false;
    }else{
        this.disablesendForDD = true;
    } 
       
    }
    nextPage() {
        this.finalInstallmentCollectionAmtMap = {};
        this.hasRowError = false;
       if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
        || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
           this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
            console.log(this.holdingSelectedRowsObj[this.pageNumber]);
        } else if(this.holdingSelectedRowsObj[this.pageNumber] != null){
           this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
         }
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
            this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
        }
        
        for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }
                 
            }
            if(this.hasRowError){
                break;
            }
            
        }
        }
    
        if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
            this.disablesendForDD = false;
        }else{
            this.disablesendForDD = true;
        }
    }
    firstPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            }  else if(this.holdingSelectedRowsObj[this.pageNumber] != null) {
                this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } 
        this.pageNumber = 1;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
            this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
        }
        for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }
                 
            }
            if(this.hasRowError){
                break;
            } 
        }
        }
    
        if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
            this.disablesendForDD = false;
        }else{
            this.disablesendForDD = true;
        } 
        
    }
    lastPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            }  else if(this.holdingSelectedRowsObj[this.pageNumber] != null) {
                this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } 
        this.pageNumber = this.totalPages;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
            this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
        }
        for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }  
            }
            if(this.hasRowError){
                break;
            } 
        }
        }
    
        if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
            this.disablesendForDD = false;
        }else{
            this.disablesendForDD = true;
        }
    }

    async handleProjectChange(event) {
         this[event.target.name] = event.target.value;
        this.getDropDownData();
    }
    async getDropDownData(){
    let projectNameData = [];
    let dropdownData = [];
    let newLocationNamesDataTableData = [];
    let newLocationNamesData = [];

    if (this.projectNameField == '' || this.projectNameField == null || this.projectNameField == undefined ) {
     dropdownData = await prepareDropdownData();

     for (let i = 0; i < dropdownData.length; i++){
       if (dropdownData[i].Project__r.Name) {
       projectNameData.push({ label: dropdownData[i].Project__r.Name, value: dropdownData[i].Project__r.Name });
       }
     }

    this.projectNamePickListValues = this.sortDropDownData(projectNameData,false,true); 

    } else {
      dropdownData = await prepareDropdownData({projectNameParam :this.projectNameField});
      newLocationNamesData = await prepareLocationNames({projectName :this.projectNameField}) ;
      for (let i = 0; i < newLocationNamesData.length; i++){
        newLocationNamesDataTableData.push({ label: newLocationNamesData[i].Name, value: newLocationNamesData[i].Name });
      }
    }   
      this.locationNamePickListValues = this.sortDropDownData(newLocationNamesDataTableData,false,true);
    }
    async resetAll() {
        this.data = [];
        this.projectNameField= '';
        this.buildingNameField=''; 
        this.ddBank='';
        this.dataMap={};
        this.maturitydate='';
        this.maturityStartdate='';
        this.maturityEnddate='';
        this.totalInstallments = 0;
        this.recordsToDisplay = [];
        this.finalInstallmentCollectionAmtMap = {};
        this.finalInstallmentCollectionIds = [];
        this.holdingSelectedRowsObj={};
        this.errors = {};
        this.draftValueMapIds = [];
        this.draftValueMap={};
        this.errorIds = [];
        this.draftSelectedIds = [];
        this.finalInstallmentCollectionCount = 0;
        this.fldsItemValues = [];
       
    }
    handleRowAction(event) {
        let updatedItemsSet = new Set();
        let selectedItemsSet = new Set(this.holdingSelectedRowsObj[this.pageNumber]);
        let loadedItemsSet = new Set();

        var rowErrorMessages = [];
        var rowErrorFieldName=[];
        var rowError={};

        
        this.data.map((event) => {
            loadedItemsSet.add(event.rowId);
        });
        if (event.detail.selectedRows) {
            event.detail.selectedRows.map((event) => {
                updatedItemsSet.add(event.rowId);
            }); 
    
          // Add any new items to the selection list
            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });        
        }
    
      loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                // Remove any items that were unselected.
                selectedItemsSet.delete(id);
            }
        });

        this.holdingSelectedRowsObj[this.pageNumber] = [...selectedItemsSet];
        console.log('handle row action');
        this.rowsTableData =[];
        let selectedRowsArray = [];
            
        var selectedRows = event.detail.selectedRows;
        this.allSelectedRows = selectedRows;
    
        rowErrorMessages.push('Enter a valid number, Entered value cannot be greater than Installment Amount and Collection Amount must be greate than 0.')
        rowErrorFieldName.push('CollectionAmount');

        for (let index = 0; index < selectedRows.length; index++) {
         this.rowsTableData.push(selectedRows[index].rowId);
         selectedRowsArray = [...selectedRowsArray, selectedRows[index].rowId];
        }
            this.selectedDatatableRows = selectedRowsArray;
            this.finalInstallmentCollectionIds = [];
            this.finalInstallmentCollectionAmtMap = {};
            this.hasRowError = false;
            for(var i=0; i<=this.totalPages; i++){
                if(this.holdingSelectedRowsObj[i] != null){
                    console.log('coming inside');
                    for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                       
                       if(this.draftValueMap[this.holdingSelectedRowsObj[i][j]] != null){
                        this.finalInstallmentCollectionAmtMap[this.holdingSelectedRowsObj[i][j]] = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].CollectionAmount);
                        this.finalInstallmentCollectionIds.push(this.holdingSelectedRowsObj[i][j]);
                       }else {
                        this.finalInstallmentCollectionAmtMap[this.holdingSelectedRowsObj[i][j]] =(this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != null || this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != undefined) ? (this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c - this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c):this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c ;
                        this.finalInstallmentCollectionIds.push(this.holdingSelectedRowsObj[i][j]);
                     }
                     let installmentAmount = this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != null || this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != undefined ? (this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c - this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c) : this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c;
                     if(this.dataMap[this.holdingSelectedRowsObj[i][j]].CollectionAmount <= 0){
                    //if(!rowError.includes(this.dataMap[this.holdingSelectedRowsObj[i][j]].Id)){
                    
                    rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]].Id]={
                      messages:rowErrorMessages,
                      fieldNames: rowErrorFieldName,
                      title: 'We found error'
                    };
               // }
                }else if(this.dataMap[this.holdingSelectedRowsObj[i][j]].CollectionAmount > installmentAmount){
                    rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]].Id]={
                        messages: 'Enter a valid number, Entered value cannot be greater than Installment Amount and Collection Amount must be greate than 0.',
                        fieldNames: 'CollectionAmount',
                        title: 'We found error'
                      };
                }  else{
                    rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]]]={};
                }
               }
        }
    }
    if(rowError != null){
        this.errors = {
             rows:rowError
         }
       }
            this.finalInstallmentCollectionCount = this.finalInstallmentCollectionIds.length;
            for(var i=0; i<=this.totalPages; i++){
                if(this.holdingSelectedRowsObj[i] != null){
                   for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                     if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                      this.hasRowError = false;
                     }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                        this.hasRowError = false;
                       }else{
                        this.hasRowError = true;
                        break;
                     }
                }
                if(this.hasRowError){
                    break;
                }
            }
        }
        
            if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
                this.disablesendForDD = false;
            }else{
                this.disablesendForDD = true;
            }
        }
           hideModalBox(event){
            this.isInitiateCollections = false;
           }
         sendForCollection(event){
            this.isLoadingModal = true;
            console.log('send for collection');
              this.isfinalInstallmentwarning = true;
        
            createDirectDebitTransaction({finalInstallmentCollectionAmtMap: this.finalInstallmentCollectionAmtMap})
           .then(result=>{
            if(result == 'Success'){
            this.isLoadingModal = false;
            this.isInitiateCollections = false;
            this.dispatchEvent(
                new ShowToastEvent({
                  title: 'Success',
                    message: 'Sent for Collection!',
                     variant: 'success'
                  })
            ); 

            this.collectionSent = true;
            this.handleSearchAll();
           }else{
            this.isInitiateCollections = false;
            this.dispatchEvent(
                new ShowToastEvent({
                  title: 'Error',
                    message: result,
                     variant: 'error'
                  })
              ); 
              this.handleSearchAll();
        }
          }).catch(error=>{
            this.isInitiateCollections = false;
            this.isLoadingModal = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error',
                  message: error.message,
                   variant: 'error'
                })
            );
            this.handleSearchAll();
        });
        }
    sendForDDCollections(event){
        this.finalInstallmentCollectionIds = [];
        this.finalInstallmentCollectionAmtMap = {};
        var allSelectedValues=[];
        this.selectedSoInstallmentMap = new Map();
        this.hasSRforSelectedInstallmentLine = false;
        var hasMultipleInstallmentLinesForSO = false;
        for(var i=0; i<=this.totalPages; i++){
        if(this.holdingSelectedRowsObj[i] != null){
           
            for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
             if(this.draftValueMap[this.holdingSelectedRowsObj[i][j]] != null){
                this.finalInstallmentCollectionAmtMap[this.holdingSelectedRowsObj[i][j]] = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].CollectionAmount);
                this.finalInstallmentCollectionIds.push(this.holdingSelectedRowsObj[i][j]);
               }else {
                this.finalInstallmentCollectionAmtMap[this.holdingSelectedRowsObj[i][j]] =(this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != null || this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != undefined) ? (this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c - this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c):this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c ;
                this.finalInstallmentCollectionIds.push(this.holdingSelectedRowsObj[i][j]);
            }
          /*  if( this.dataMap[this.holdingSelectedRowsObj[i][j]].serviceRequest != undefined && this.dataMap[this.holdingSelectedRowsObj[i][j]].serviceRequest != null){
                this.hasSRforSelectedInstallmentLine = true;
                break;
            } */
        }
    }
      }

    /*  for(var i=0; i<=this.totalPages; i++){
        if(this.holdingSelectedRowsObj[i] != null){
           for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
           if( this.dataMap[this.holdingSelectedRowsObj[i]].serviceRequest != undefined && this.dataMap[this.holdingSelectedRowsObj[i]].serviceRequest != null){
            this.hasSRforSelectedInstallmentLine = true;
            break;
           }
        }
      }
    } */
    for(let i=0; i<this.finalInstallmentCollectionIds.length;i++){
        let selectedInstallmentLines = [];
        selectedInstallmentLines = this.selectedSoInstallmentMap[this.dataMap[ this.finalInstallmentCollectionIds[i]].installment.SalesOrder__c] != null ? this.selectedSoInstallmentMap[this.dataMap[ this.finalInstallmentCollectionIds[i]].installment.SalesOrder__c]: [];
        selectedInstallmentLines.push(this.dataMap[this.finalInstallmentCollectionIds[i]].installment)
        this.selectedSoInstallmentMap[this.dataMap[this.finalInstallmentCollectionIds[i]].installment.SalesOrder__c] = selectedInstallmentLines;
    
        if(this.selectedSoInstallmentMap[this.dataMap[this.finalInstallmentCollectionIds[i]].installment.SalesOrder__c].length > 1){
            hasMultipleInstallmentLinesForSO = true;
        }

    }
    console.log('this.selectedSoInstallmentMap:::'+this.selectedSoInstallmentMap);
    
    
this.finalInstallmentCollectionCount = this.finalInstallmentCollectionIds.length;
if(hasMultipleInstallmentLinesForSO){
    const evt = new ShowToastEvent({
        title: 'Installment Lines',
        message: 'You have Selected multiple Installments for same Sales Order, Kindly make sure only one intsallment is selected for one Sales Order',
        variant: 'error',
    });
    this.dispatchEvent(evt);
}
else if(this.hasSRforSelectedInstallmentLine){
    const evt = new ShowToastEvent({
        title: 'Installment Lines',
        message: 'The Selected Installment Lines are having active SR'+'\'s. Kindly Deleselect such Installment Lines',
        variant: 'error',
    });
    this.dispatchEvent(evt);
}else{
    if(this.finalInstallmentCollectionCount >= CollectionThreshold){
       const evt = new ShowToastEvent({
            title: 'Installment Lines',
            message: 'Maximum '+CollectionThreshold+' Instalment Lines can be sent for collections. Kindly revist your selection' ,
            variant: 'error',
        });
        this.dispatchEvent(evt);
      
      // this.popupMessage = 'Maximum 50 Instalment Lines can be sent for collections. Kindly revist your selection';
    }else if(this.finalInstallmentCollectionCount < CollectionThreshold && this.finalInstallmentCollectionCount > 0){
       this.isInitiateCollections = true;
       this.isfinalInstallmentwarning = false;
       this.popupMessage = 'You have selected '+this.finalInstallmentCollectionCount+' installments for collection. Are you sure you want to proceed?';
    }else if(this.finalInstallmentCollectionCount == 0) {
        this.popupMessage = 'You have selected '+this.finalInstallmentCollectionCount+' installments for collection.'
        this.isfinalInstallmentwarning = true;
    }
}
     
      console.log('this.finalInstallmentCollectionIds:::'+this.finalInstallmentCollectionIds);
      console.log('final Map:::'+this.finalInstallmentCollectionAmtMap);
      console.log('holdingSelectedRowsObj Map:::'+this.holdingSelectedRowsObj);
      console.log('draftValueMap Map:::'+this.draftValueMap);
      console.log('allSelectedValues::'+allSelectedValues);
      
    }

    handleSortdata(event) {
        
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        
        let parseData = JSON.parse(JSON.stringify(this.recordsToDisplay));
        let keyValue = (a) => {
            return a[fieldname];
        };

        let isReverse = direction === 'asc' ? 1: -1;

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });

        this.recordsToDisplay = parseData;

    }
    sortDropDownData(fieldname,assignedToFlag,noneFlag) {
        let parseData = JSON.parse(JSON.stringify(fieldname));
        let filteredSortedData= [];
        const filteredData = parseData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);


        let keyValue = (a) => {
            return a['label'];
        };
        
        filteredData.sort((x, y) => {
            if (x !== 'None' && y !== 'None') {
                x = keyValue(x) ? keyValue(x) : ''; 
                y = keyValue(y) ? keyValue(y) : '';
                return  ((x > y) - (y > x));
            }
        });
        if (noneFlag) {
            filteredSortedData.push({ label: "None", value: null });
        }
        if (assignedToFlag) {
            filteredSortedData.push({ label: "Unassigned", value: 'Unassigned' });
        }
        filteredData.forEach(element => {
            filteredSortedData.push({ label: element.label, value: element.value });
        });

        return filteredSortedData
    }

    handlecellchange(event){
    console.log('handle Cell Change');   
    var draftValues = event.detail.draftValues;
    var rowErrorMessages = [];
    var rowErrorFieldName=[];
    var rowError={};
    let draftSelectedIds = this.selectedDatatableRows;
    
    //this.selectedDatatableRows = draftSelectedIds;
    rowErrorMessages.push('Enter a valid number, Entered value cannot be greater than Installment Amount and Collection Amount must be greate than 0.')
    rowErrorFieldName.push('CollectionAmount');
    rowError[draftValues[0].Id]={
        messages:rowErrorMessages,
        fieldNames: rowErrorFieldName,
        title: 'We found error'

    };
    /*if(draftValues[0].CollectionAmount > this.dataMap[draftValues[0].Id].OutstandingAmount__c){
        this.errors = {
            rows:rowError
        }
    }else{
        this.errors = {};
    } */
    console.log('draftValues::'+draftValues);

    if(draftValues.length>0){
        for(let i=0; i<draftValues.length; i++){
            this.draftValueMap[draftValues[i].Id] = draftValues[i]; 
            this.draftValueMapIds.push(draftValues[i].Id);
        if(draftValues[i].CollectionAmount != 0 && draftValues[i].CollectionAmount != null){
           if(!draftSelectedIds.includes(draftValues[i].Id)) {
            draftSelectedIds.push(draftValues[0].Id);
        }
    }
   }
        this.selectedDatatableRows = [...draftSelectedIds];
        this.holdingSelectedRowsObj[this.pageNumber] = this.selectedDatatableRows;
 }
    
     if(this.draftValueMapIds != null){
        for(let i=0; i<this.draftValueMapIds.length; i++){
           console.log(this.draftValueMap[this.draftValueMapIds[i]]);
              let installmentAmount = this.dataMap[this.draftValueMapIds[i]].AmountReceived__c != null || this.dataMap[this.draftValueMapIds[i]].AmountReceived__c != undefined ? (this.dataMap[this.draftValueMapIds[i]].InstallmentAmount__c - this.dataMap[this.draftValueMapIds[i]].AmountReceived__c) : this.dataMap[this.draftValueMapIds[i]].InstallmentAmount__c;
            if(this.draftValueMap[this.draftValueMapIds[i]].CollectionAmount > installmentAmount){
                this.errorIds.push(this.draftValueMapIds[i]);
                rowError[this.draftValueMapIds[i]]={
                    messages:rowErrorMessages,
                    fieldNames: rowErrorFieldName,
                    title: 'We found error'
                };
            }else{
                rowError[this.draftValueMapIds[i]]={};
             }
        }
    }
        if(rowError != null){
           this.errors = {
                rows:rowError
            }
          }
          this.finalInstallmentCollectionIds = [];
          this.finalInstallmentCollectionAmtMap = {};
          this.hasRowError = false;
          for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }
                 
            }
            if(this.hasRowError){
                break;
            }
            
        }
        }
    
        for(var i=0; i<=this.totalPages; i++){
                if(this.holdingSelectedRowsObj[i] != null){
                    console.log('coming inside');
                    for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                        console.log('j::'+j);
                        if(this.draftValueMap[this.holdingSelectedRowsObj[i][j]] != null){
                        this.finalInstallmentCollectionAmtMap[this.holdingSelectedRowsObj[i][j]] = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].CollectionAmount);
                        this.finalInstallmentCollectionIds.push(this.holdingSelectedRowsObj[i][j]);
                       }else {
                        this.finalInstallmentCollectionAmtMap[this.holdingSelectedRowsObj[i][j]] =(this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != null || this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c != undefined) ? (this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c - this.dataMap[this.holdingSelectedRowsObj[i][j]].AmountReceived__c):this.dataMap[this.holdingSelectedRowsObj[i][j]].InstallmentAmount__c ;
                        this.finalInstallmentCollectionIds.push(this.holdingSelectedRowsObj[i][j]);
                    }
                }
                }
              }
              this.finalInstallmentCollectionCount = this.finalInstallmentCollectionIds.length;

              if(this.finalInstallmentCollectionCount>0 && !this.hasRowError){
                this.disablesendForDD = false;
              }else{
                this.disablesendForDD = true;
              }
            console.log('length::'+this.holdingSelectedRowsObj[this.pageNumber].length);
   
    console.log('this.recordsToDisplay::'+this.recordsToDisplay);
    console.log('this.selectedDatatableRows:::'+this.selectedDatatableRows);
    //  this.dataMap
    // this.draftValueMap
    }
   /* saveHandleAction(event) {
       
        this.fldsItemValues = event.detail.draftValues;
        const inputsItems = this.fldsItemValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

       const promises = inputsItems.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records Updated Successfully!!',
                    variant: 'success'
                })
            );
            this.fldsItemValues = [];
            return this.refresh();
        }).catch(error => {
            var errorMsg = error.body.message;
           if(error.body.output.fieldErrors.AmountReceived__c.length>0){
            for(let i=0; i< error.body.output.fieldErrors.AmountReceived__c.length ; i++){
                errorMsg = error.body.output.fieldErrors.AmountReceived__c[i].message;
            }
           }
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMsg,
                    variant: 'error'
                })
            );
        }).finally(() => {
            this.fldsItemValues = [];
        });
    } */
    async refresh() {
        await refreshApex(this.recordsToDisplay);
    }
    
}