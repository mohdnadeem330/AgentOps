import { LightningElement, wire, track } from 'lwc';

import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getAllComissions from '@salesforce/apex/CommissionsReportController.getAllComissions';


import {
    EXAMPLES_COLUMNS_DEFINITION_BASIC,
    EXAMPLES_DATA_BASIC,
} from './columnsDefinition';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
export default class CommissionsReport extends LightningElement {
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";

    //Filter js Start Here//
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconName = '';
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    }
    //Filter js End Here// 
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    @track

    filterStartDate;
    filterEndDate;
    comissionData = [];
    selectRowID;
    showPopUpActions = false;
    tableColumns = EXAMPLES_COLUMNS_DEFINITION_BASIC;
    tableData;
    propertyNameValues = [];
    unitValues = [];
    statusValues = [];
    invoiceURL = '/sfc/servlet.shepherd/document/download/069260000018r4HAAQ';
    soString = '';
    isModalOpen = false;
    @track showSpinner = false;
    @track toExpandRow = [];
    @track newData = false;
    @track gridExpandedRows = [];
    @track arr = [];

    currentPage = 1;
    pageSize = 5;

    connectedCallback() {
        var todayDate = new Date();
        this.filterStartDate = todayDate.getFullYear() + '-1-1';
        this.filterEndDate = todayDate.getFullYear() + '-' + (todayDate.getMonth() + 1) + '-' + todayDate.getDate();
        this.initCommissionRecords();
    }
    subStatusMapping = {
        'Pending with Sales Manager': 'Pending with Sales Manager',
        'Printing Pending with Sales Admin': 'Pending with Sales Manager',
        'Contract Document Printed': 'Pending with Sales Manager',
        'Pending with Sales Admin': 'Pending with Sales Manager',
        'Accepted by Sales Admin': 'Pending with Sales Manager',
        'Rejected By Sales Admin': 'Pending with Sales Manager',
        'Submitted to Legal': 'Pending with Legal',
        'Approved By Legal': 'Pending with Legal',
        'Rejected By Legal': 'Pending with Legal',
        'Submitted to CM': 'Pending with Customer Management',
        'Validated By CM': 'Pending with Customer Management',
        'Rejected By CM': 'Pending with Customer Management',
        'SPA Sign-off Pending': 'Pending with Customer Management',
        'Accepted by CM': 'Pending with Customer Management'
    }


    //Wired Calls

    @wire(getRecord, { recordId: strUserId, fields: [PROFILE_NAME_FIELD] })

    wireuser({ error, data }) {
        if (error) {
            console.error(error);
        } else if (data) {


        }
    }

    //normal methods
    initCommissionRecords() {
        this.showSpinner = true;

        getAllComissions({ startDate: new Date(this.filterStartDate), endDate: new Date(this.filterEndDate) })
            .then(data => {
                console.log(data);
                this.comissionData = data;
                this.handleFilterChange();
                this.showSpinner = false;
            })
            .catch(error => {
                console.error(error);
                this.comissionData = undefined;
                this.tableData = [];
                this.showSpinner = false;
            });

    }

    clearFilter() {
        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        for (let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value = '';
        }
        this.filterStartDate = undefined;
        this.filterEndDate = undefined;
        this.initCommissionRecords();
    }

    handleFilerChnageWithDate() {
        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        var startDateForFilter;
        var endDateForFilter;
        for (let j = 0; j < allSearchFields.length; j++) {
            if (allSearchFields[j].value != undefined && allSearchFields[j].value != '') {

                if (allSearchFields[j].dataset.field == 'startDate') {
                    startDateForFilter = allSearchFields[j].value;
                } else if (allSearchFields[j].dataset.field == 'endDate') {
                    endDateForFilter = allSearchFields[j].value;
                }

            }
        }
        console.log('-- Handle the filter --' + this.startDateForFilter);
        console.log('-- Handle the filter --' + this.endDateForFilter);

        if (startDateForFilter || endDateForFilter) {
            console.log('reload ');
            this.filterStartDate = startDateForFilter;
            this.filterEndDate = endDateForFilter;
            this.initCommissionRecords();
        } else {
            console.log('just filter ');
            this.handleFilterChange();
        }
    }


    handleFilterChange() {
        this.tableData = [];
        this.propertyNameValues = [];
        this.unitValues = [];
        this.statusValues = [];

        let allSearchFields = this.template.querySelectorAll('.comissionFilters');

        for (let i = 0; i < this.comissionData.length; i++) {
            var recordFiltered = false;

            var comissionObj = {
                column0: this.comissionData[i].Id,
                column1: this.comissionData[i].BrokerAgency__c ? this.comissionData[i].BrokerAgency__r.Name : '',
                column2: this.comissionData[i].BrokerAgent__c ? this.comissionData[i].BrokerAgent__r.Name : '',
                column3: this.comissionData[i].SalesOrder__r ? this.comissionData[i].SalesOrder__r.ProjectName__c : '',
                column4: (this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Unit__c) ? this.comissionData[i].SalesOrder__r.Unit__r.Name : '',
                column5: this.comissionData[i].CustomerName__c ? this.comissionData[i].CustomerName__c : '',//(this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Opportunity__c && this.comissionData[i].SalesOrder__r.Opportunity__r.Contact__c )? this.comissionData[i].SalesOrder__r.Opportunity__r.Contact__r.Name:((this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Opportunity__c && this.comissionData[i].SalesOrder__r.Opportunity__r.AccountId )? this.comissionData[i].SalesOrder__r.Opportunity__r.Account.Name:''),
                column6: this.comissionData[i].SalesOrder__r ? this.comissionData[i].SalesOrder__r.NetAmount__c : '',
                column7: this.comissionData[i].OrderDate__c,
                column8: this.comissionData[i].CommissionAmount__c,
                column9: (this.comissionData[i].TotalExternalCommissionPercentage__c / 100),
                column10: this.comissionData[i].Status__c,
                column12: undefined,
                column13: undefined,
                column14: this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Status__c == 'Sold' ? 'Sold' : (this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.SubStatus__c ? (this.subStatusMapping[this.comissionData[i].SalesOrder__r.SubStatus__c] ? this.subStatusMapping[this.comissionData[i].SalesOrder__r.SubStatus__c] : this.comissionData[i].SalesOrder__r.SubStatus__c) : ''),
                statusIcon: undefined,
                _children: [{
                    column0: this.comissionData[i].Id + '_1',
                    column1: '',
                    column2: 'Invoice # : ' + this.comissionData[i].InvoiceNumber__c,
                    column3: '',
                    column4: 'Installment # : ' + this.comissionData[i].InstalmentNumber__c,
                    column5: 'Paid Amount : ' + (this.comissionData[i].Status__c === 'Paid' ? this.comissionData[i].CommissionAmountWithVAT__c : '-'),
                    column6: '',
                    column7: undefined,
                    column8: undefined,
                    column9: undefined,
                    column10: undefined,
                    column12: undefined,
                    column13: undefined,
                    column13: undefined
                },
                {
                    column0: this.comissionData[i].Id + '_2',
                    column1: '',
                    column2: 'Payment Due Date : ' + (this.comissionData[i].ClearedDate__c ? this.comissionData[i].ClearedDate__c : '-'),
                    column3: '',
                    column4: '',//this.comissionData[i].PaymentDueDate__c ,
                    column5: 'Invoice Date : ' + (this.comissionData[i].InvoiceDate__c ? this.comissionData[i].InvoiceDate__c : '-'),
                    column6: undefined,
                    column7: undefined,
                    column8: undefined,
                    column9: undefined,
                    column10: undefined,
                    column12: undefined,
                    column13: undefined,
                    column13: undefined
                }]
            };

            //APPLY FILTERS
            for (let j = 0; j < allSearchFields.length; j++) {
                if (allSearchFields[j].value != undefined && allSearchFields[j].value != '') {

                    if (this.comissionData[i].OrderDate__c && this.comissionData[i].OrderDate__c != null && allSearchFields[j].dataset.field == 'startDate') {
                        /*var d1 = new Date(this.comissionData[i].OrderDate__c) ;
                        var d2 = new Date(allSearchFields[j].value) ;
                       
                        if(d1 < d2){
                            recordFiltered=true;
                            break;
                        }*/
                    } else if (this.comissionData[i].OrderDate__c && this.comissionData[i].OrderDate__c != null && allSearchFields[j].dataset.field == 'endDate') {
                        /*var d1 = new Date(this.comissionData[i].OrderDate__c) ;
                        var d2 = new Date(allSearchFields[j].value) ;
                      
                        if(d1 > d2){
                            recordFiltered=true;
                            break;
                        }*/

                    } else if (comissionObj[allSearchFields[j].dataset.field] != allSearchFields[j].value) {
                        recordFiltered = true;
                        break;
                    }
                }
            }
            //If not filtered then add

            if (!recordFiltered) {
                switch (comissionObj.column10) {
                    case 'Not Ready':
                        comissionObj.statusIcon = 'utility:clock';
                        break;
                    case 'Ready for Submission':
                        comissionObj.statusIcon = 'utility:internal_share';
                        break;
                    case 'Paid':
                        comissionObj.statusIcon = 'utility:contract_payment';
                        break;
                    case 'Sent to Finance':
                        comissionObj.statusIcon = 'utility:senttofinance';
                        break;
                    case 'Rejected':
                        comissionObj.statusIcon = 'utility:ban';
                        break;
                    case 'Pending Invoice Verification':
                        comissionObj.statusIcon = 'utility:invoice_verification';
                        break;
                    case 'Pending Finance Verification':
                        comissionObj.statusIcon = 'utility:finance_verification';
                        break;
                    case 'Fixed':
                        comissionObj.statusIcon = 'utility:all';
                        break;
                    default:
                        comissionObj.statusIcon = 'utility:ban';
                };


                //initiate filter
                if (comissionObj.column3 && comissionObj.column3 != '' && this.propertyNameValues.findIndex((item) => item.label === comissionObj.column3) === -1) {
                    this.propertyNameValues.push({ label: comissionObj.column3, value: comissionObj.column3 });
                }
                if (comissionObj.column4 && comissionObj.column4 != '' && this.unitValues.findIndex((item) => item.label === comissionObj.column4) === -1) {
                    this.unitValues.push({ label: comissionObj.column4, value: comissionObj.column4 });
                }
                if (comissionObj.column10 && comissionObj.column10 != '' && this.statusValues.findIndex((item) => item.label === comissionObj.column10) === -1) {
                    this.statusValues.push({ label: comissionObj.column10, value: comissionObj.column10 });
                }
                //add to final list
                this.tableData.push(comissionObj);

            }

        }

    }

    //Poupup Method
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.isModalOpen = event.detail.isOpen;
        this.initCommissionRecords();
    }

    //Expand collaps
    async expandCollapseRows() {
        const treegrid = this.template.querySelector('.aldar-lightning-tree-grid');
        let selectedRow;
        if (this.toExpandRow == undefined || this.toExpandRow == null || this.toExpandRow.length == 0) {
            selectedRow = treegrid.getSelectedRows();
        } else {
            selectedRow = this.toExpandRow;
        }
        //expand row
        selectedRow.forEach(async element => {
            var item = (this.toExpandRow == undefined || this.toExpandRow == null || this.toExpandRow.length == 0) ? element.column0 : element;
            if (this.gridExpandedRows.indexOf(item) == -1) {

                this.gridExpandedRows.push(item);
                this.gridExpandedRows = [...this.gridExpandedRows];
            }
            if (this.arr.indexOf(item) == -1) {
                this.arr.push(item);
            }
        });

        // get array from selected row , becase it's proxy object then it will return array of object,so I'm getting field name to make arr2 as aray of string.
        let arr2 = []
        if (this.toExpandRow == undefined || this.toExpandRow == null || this.toExpandRow.length == 0) {
            arr2 = Array.from(selectedRow).map((item) => { return item.column0 });
        } else {
            arr2 = selectedRow;
        }

        let arr1 = this.arr;
        //getting the difference between what has been clicked and what still is clicked until now. (for more check this
        //:https://stackoverflow.com/questions/1187518/how-to-get-the-difference-between-two-arrays-in-javascript)
        let difference = arr1
            .filter(x => !arr2.includes(x))
            .concat(arr2.filter(x => !arr1.includes(x)));

        // remove items that de selected (collapse row)
        difference.forEach((item) => {
            this.gridExpandedRows.splice(this.gridExpandedRows.indexOf(item), 1);
            this.gridExpandedRows = [...this.gridExpandedRows];
            this.arr.splice(this.arr.indexOf(item), 1);
        });
        this.newData = true;
    }
    expandCollapseRowsRightSide(event) {
        //event.detail.row.column0
        if (this.toExpandRow.length > 0) {
            this.toExpandRow.map((item) => { return item.column0; });
        }

        if (this.toExpandRow.indexOf(event.detail.row.column0) == -1 && !event.detail.row.isExpanded) {
            this.toExpandRow.push(event.detail.row.column0);
        } else if (this.toExpandRow.indexOf(event.detail.row.column0) != -1 && event.detail.row.isExpanded) {
            this.toExpandRow.splice(this.toExpandRow.indexOf(event.detail.row.column0), 1);
        }

        if (event.detail.action.name === "Expand") {
            this.expandCollapseRows();
        } else {
            if (event.detail.row.column10 != 'Not Ready') {
                this.showPopUpActions = (event.detail.row.column10 == 'Ready for Submission' || event.detail.row.column10 == 'Fixed');
                this.selectRowID = event.detail.row.column0;
                this.openModal();
            } else {
                this.selectRowID = undefined
            }

        }

    }

    exportToCSV() {
        let columnHeader = ["Customer", "Agency Name", "Agent Name ", "Property", "Unit Number", "Net Price", "Order Date", "Comission", "Rate", 'Sales Order Status', "Status"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["column5", "column1", "column2", "column3", "column4", "column6", "column7", "column8", "column9", "column14", "column10"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.tableData;
        let csvIterativeData;
        let csvSeperator;
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
                if (counter > 0) { csvIterativeData += csvSeperator; }
                if (jsonRecordsData[i][dataKey] !== null &&
                    jsonRecordsData[i][dataKey] !== undefined
                ) {
                    console.log(jsonRecordsData[i][dataKey]);
                    csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';
                } else {
                    csvIterativeData += '""';
                }
                counter++;
            }
            csvIterativeData += newLineCharacter;
        }
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);
        csvIterativeData = csvIterativeData.replace(' ', '_SPACE_');
        csvIterativeData = csvIterativeData.replace(/"/g, '');
        csvIterativeData = csvIterativeData.replace('_SPACE_', ' ');
        var downloadLink = document.createElement("a");
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,' + csvIterativeData;
        downloadLink.download = 'Commission Report.xls.csv';
        downloadLink.click();
    }

    // Add a method to calculate the total number of pages:
    get totalPages() {
        if (this.tableData) {
            return Math.ceil(this.tableData.length / this.pageSize);
        }
        return 0;
    }

    // Add methods to handle Previous and Next button clicks:
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    // Modify your tableData to display only the items for the current page:
    get paginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        if (!this.tableData) {
            return [];
        } else {
            return this.tableData.slice(start, end);
        }
    }

}