import { LightningElement, track } from 'lwc';
import getSaleManagers from "@salesforce/apex/CommissionCalculatorController.getSaleManagers";
import getSaleManagersCommission from "@salesforce/apex/CommissionCalculatorController.getSaleManagersCommission";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const mainColumns = [

    { label: 'Unit Number', fieldName: 'unitlinkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'unitName' }, target: '_blank', tooltip: { fieldName: 'unitName' }, sortable: "true" }},

    { label: 'Sales Order', fieldName: 'linkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'salesOrderName' }, target: '_blank', tooltip: { fieldName: 'salesOrderName' }, sortable: "true" }},

    { label: 'Commission Name', fieldName: 'commissionlinkName', type: 'url',  sortable: "true" ,
    typeAttributes: {label: { fieldName: 'CommissionLineItem__c' }, target: '_blank', tooltip: { fieldName: 'CommissionLineItem__c' }, sortable: "true" }},
    {label: 'Equity', fieldName: 'Equity__c', sortable: "true"},
    {label: 'Payout Amount', fieldName: 'PayoutAmount__c', sortable: "true"},
    {label: 'Future Commission', fieldName: 'FutureCommission__c', sortable: "true"},
    {label: 'Payout Date', fieldName: 'PayoutDate__c', sortable: "true"},
    {label: 'SalesHead Payout Amount', fieldName: 'SalesHeadPayoutAmount__c', sortable: "true"},
    {label: 'Director Payout Amount', fieldName: 'DirectorPayoutAmount__c', sortable: "true"},
    {label: 'Broker Head Payout Amount', fieldName: 'BrokerHeadPayoutAmount__c', sortable: "true"},
    {label: 'ExecDirector Payout Amount', fieldName: 'ExecDirectorPayoutAmount__c', sortable: "true"},
    {label: 'CCO Payout Amount', fieldName: 'CCOPayoutAmount__c', sortable: "true"},
]

export default class CommissionCalculator extends LightningElement {

    yearField;
    monthField;
    salesManagerPickListValues;
    salesManagerField;
    columns = mainColumns;
    data = [];
    futureData = [];
    sortBy;
    sortDirection;
    currentPayoutAmount = 0;
    futurepayoutAmount = 0;
    isLoading = false;
    disableCalculateCommission = true;
    showExcelButton = false;
    profileField;
    salesManagerdisabled = true;
    async connectedCallback() {
        console.log('connectedCallback');
      
    }

    get profilePickListValues() {
        return [
            { label: 'Broker Manager', value: 'Broker Manager' },
            { label: 'Sales Manager', value: 'Sales Manager' },
            { label: 'Resales Manager', value: 'Resales Manager' },
        ];
    }
    
    resetAll(){
        this.profileField = '';
        this.salesManagerdisabled = true;
        this.salesManagerField = '';
        this.monthField = '';
        this.yearField = '';
        this.data = [];
        this.disableCalculateCommission = true;
        this.currentPayoutAmount = 0;
        this.futurepayoutAmount = 0; 
        this.showExcelButton = false;
      
    }

    handleProfileChange(event){
        this.profileField = event.detail.value;
        this.salesManagerdisabled = false;
        this.salesManagerField = '';
        this.monthField = '';
        this.yearField = '';
        this.data = [];
        this.disableCalculateCommission = true;
        this.currentPayoutAmount = 0;
        this.futurepayoutAmount = 0;
        this.getSaleManagersList();
      
    }

   async getSaleManagersList(){
    let salesManagerData = [];
    let dropdownData = [];
    if(this.salesManagerField == '' || this.salesManagerField == null  || this.salesManagerField == undefined){
        dropdownData = await getSaleManagers({ProfileName:this.profileField});

        for (let i = 0; i < dropdownData.length; i++){
            if (dropdownData[i].Name) {
                salesManagerData.push({ label: dropdownData[i].Name, value: dropdownData[i].Id });
            }
          }
          this.salesManagerPickListValues = this.sortDropDownData( salesManagerData,false,true);
    }
  }
    get monthPickListValues() {
        return [
            { label: 'Jan', value: '1' },
            { label: 'Feb', value: '2' },
            { label: 'Mar', value: '3' },
            { label: 'Apr', value: '4' },
            { label: 'May', value: '5' },
            { label: 'Jun', value: '6' },
            { label: 'Jul', value: '7' },
            { label: 'Aug', value: '8' },
            { label: 'Sep', value: '9' },
            { label: 'Oct', value: '10' },
            { label: 'Nov', value: '11' },
            { label: 'Dec', value: '12' }
        ];
    }

    get yearPickListValues() {
        return [
            { label: '2022', value: '2022' },
            { label: '2023', value: '2023' },
        ];
    }
    handleSalesManagerChange(event){
     this[event.target.name] = event.target.value;
    if(this.yearField != undefined && this.yearField !=''  && this.monthField != undefined && this.monthField !='' && this.salesManagerField != undefined && this.salesManagerField !=''){
       this.disableCalculateCommission = false;
    }else{
        this.disableCalculateCommission = true;
    }
   
    }
    handleyearChange(event){
        this.yearField = event.detail.value;
        if(this.yearField != undefined && this.yearField !=''  && this.monthField != undefined && this.monthField !='' && this.salesManagerField != undefined && this.salesManagerField !=''){
            this.disableCalculateCommission = false;
         }else{
             this.disableCalculateCommission = true;
         }
        
    }
    handlemonthChange(event){
        this.monthField = event.detail.value;
        if(this.yearField != undefined && this.yearField !=''  && this.monthField != undefined && this.monthField !='' && this.salesManagerField != undefined && this.salesManagerField !=''){
            this.disableCalculateCommission = false;
         }else{
             this.disableCalculateCommission = true;
         }
        
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
   async calculateCommission(event){
    console.log('calculate commission');
    this.isLoading=true;
    this.data = [];
    this.currentPayoutAmount = 0;
    this.futurepayoutAmount = 0;
    this.showExcelButton = false;
        let salesManagerField = this.salesManagerField;
        const newData = await getSaleManagersCommission({ProfileName:this.profileField,SalesManagerId:salesManagerField, strMonth:this.monthField, strYear:this.yearField });
       
        console.log('newData::'+newData);
        console.log('newData::'+ JSON.stringify( newData));
        newData.forEach(record => {

            record.unitlinkName = '/'+record.unitId;
            console.log('record:::'+record);
            if(record.payoutLine.FutureCommission__c == 'Current' || this.profileField == 'Broker Manager'){
                this.currentPayoutAmount = this.currentPayoutAmount+Number(record.payoutLine.PayoutAmount__c);
            }
            if(record.payoutLine.FutureCommission__c == 'Future'){
                this.futurepayoutAmount = this.futurepayoutAmount+Number(record.payoutLine.PayoutAmount__c);
            }
            record.linkName = '/'+record.payoutLine.SalesOrder__c;
            record.commissionlinkName = '/'+record.payoutLine.CommissionLineItem__c;
            record.CommissionLineItem__c = record.commissionName;
            record.Equity__c = record.equity;
            record.unitName = record.unitName;
            record.salesOrderName = record.salesOrderName;
            record.PayoutAmount__c = Number(record.payoutLine.PayoutAmount__c).toFixed(2);
            record.FutureCommission__c = record.payoutLine.FutureCommission__c;
            record.SalesHeadPayoutAmount__c = record.payoutLine.SalesHeadPayoutAmount__c != undefined ? Number(record.payoutLine.SalesHeadPayoutAmount__c).toFixed(2): 0;
            record.DirectorPayoutAmount__c = record.payoutLine.DirectorPayoutAmount__c != undefined? Number(record.payoutLine.DirectorPayoutAmount__c).toFixed(2):0;
            record.BrokerHeadPayoutAmount__c = record.payoutLine.BrokerHeadPayoutAmount__c != undefined? Number(record.payoutLine.BrokerHeadPayoutAmount__c).toFixed(2):0;
            record.ExecDirectorPayoutAmount__c = record.payoutLine.ExecDirectorPayoutAmount__c !=undefined ? Number(record.payoutLine.ExecDirectorPayoutAmount__c).toFixed(2):0;
            record.CCOPayoutAmount__c = record.payoutLine.CCOPayoutAmount__c !=undefined ? Number(record.payoutLine.CCOPayoutAmount__c).toFixed(2): 0;
            record.PayoutDate__c = record.payoutLine.PayoutDate__c;
            record.SalesManager__c = record.payoutLine.SalesManager__c;
            record.salesManagerName = record.salesManagerName;
        });
         this.currentPayoutAmount = this.currentPayoutAmount.toFixed(2);
        this.futurepayoutAmount = this.futurepayoutAmount.toFixed(2);
        this.data= newData;
        if(this.data.length>0){
            this.showExcelButton = true;
            const evt = new ShowToastEvent({
                title: 'Cogratulations',
                message: 'You got your commission Report' ,
                variant: 'success',
            });
            this.dispatchEvent(evt);
        }else {
            const evt = new ShowToastEvent({
                title: 'Sorry',
                message: 'No Commission calculated for the selected month and year' ,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
       // this.futureData=futurenewData;
        this.isLoading=false;
    }

    handleSortdata(event) {
        
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        
        let parseData = JSON.parse(JSON.stringify(this.data));
        let keyValue = (a) => {
            return a[fieldname];
        };

        let isReverse = direction === 'asc' ? 1: -1;

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });

        this.data = parseData;

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

    exportToCSV() {  
        console.log('excel::');
        let columnHeader = ["Unit Number", "Commission Name", "Equity", "Payout Amount", "Future Commission","Payout Date","SalesHead Payout Amount","Director Payout Amount",'Broker Head Payout Amount',"ExecDirector Payout Amount", "CCO Payout Amount", "SalesManager Id", "Sales Manager Name"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["unitName","CommissionLineItem__c", "Equity__c", "PayoutAmount__c","FutureCommission__c","PayoutDate__c","SalesHeadPayoutAmount__c","DirectorPayoutAmount__c","BrokerHeadPayoutAmount__c","ExecDirectorPayoutAmount__c", "CCOPayoutAmount__c", "SalesManager__c","salesManagerName"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.data;  
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
        csvIterativeData = csvIterativeData.replace(/"/g, '');
        csvIterativeData = csvIterativeData.replace('_SPACE_',' ');
        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Commission Payout Report.xls.csv';
        downloadLink.click();
    }
}