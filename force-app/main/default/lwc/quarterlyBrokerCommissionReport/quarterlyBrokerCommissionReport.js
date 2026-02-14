import { LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import {
    EXAMPLES_COLUMNS_DEFINITION_BASIC,
    EXAMPLES_DATA_BASIC,
} from './columnsDefinition';
import getAllComissions from '@salesforce/apex/QuarterlyBrokerCommissionController.getAllComissions';
export default class QuarterlyBrokerCommissionReport extends LightningElement {
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    tableColumns = EXAMPLES_COLUMNS_DEFINITION_BASIC;
    quarterOptions = [
        { label: 'Q1', value: 'Q1' },
        { label: 'Q2', value: 'Q2' },
        { label: 'Q3', value: 'Q3' },
        { label: 'Q4', value: 'Q4' }
    ];
    yearOptions = [
        { label: '2022', value: '2022' },
        { label: '2023', value: '2023' },
        { label: '2024', value: '2024' },
        { label: '2025', value: '2025' },
        { label: '2026', value: '2026' },
        { label: '2027', value: '2027' },
        { label: '2028', value: '2028' },
        { label: '2029', value: '2029' }
    ];
    showSpinner;
    @track comissionData = [];
    @track tableData = [];
    @track gridExpandedRows = [];
    @track newData = false;

    currentPage = 1;
    pageSize = 5;

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
    };
    isModalOpen = false;

    connectedCallback() {
        this.initCommissionRecords();
    }

    initCommissionRecords() {
        this.showSpinner = true;
        getAllComissions()
            .then(data => {
                console.log('data ', data);
                this.comissionData = data;
                this.buildData(undefined, undefined);
            })
            .catch(error => {
                console.log('error ', error);
                this.comissionData = undefined;
                this.tableData = [];
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    buildData(quarter, year) {
        this.tableData = [];
        for (let i = 0; i < this.comissionData.length; i++) {
            var recordFiltered = false;
            console.log('this.comissionData[i] ', this.comissionData[i]);
            var comissionObj = {
                column0: this.comissionData[i].Id,
                column1: this.comissionData[i].BrokerAgency__c ? this.comissionData[i].BrokerAgency__r.Name : '',
                column2: this.comissionData[i].BrokerAgent__c ? this.comissionData[i].BrokerAgent__r.Name : '',
                column3: this.comissionData[i].SalesOrder__r ? this.comissionData[i].SalesOrder__r.ProjectName__c : '',
                column4: (this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Unit__c) ? this.comissionData[i].SalesOrder__r.Unit__r.Name : '',
                column5: this.comissionData[i].Quarter__c ? this.comissionData[i].Quarter__c : '',//(this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Opportunity__c && this.comissionData[i].SalesOrder__r.Opportunity__r.Contact__c )? this.comissionData[i].SalesOrder__r.Opportunity__r.Contact__r.Name:((this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Opportunity__c && this.comissionData[i].SalesOrder__r.Opportunity__r.AccountId )? this.comissionData[i].SalesOrder__r.Opportunity__r.Account.Name:''),
                column6: this.comissionData[i].SalesOrder__r ? this.comissionData[i].SalesOrder__r.NetAmount__c : '',
                column7: this.comissionData[i].OrderDate__c,
                column8: this.comissionData[i].CommissionAmount__c,
                column9: '',
                column10: this.comissionData[i].Status__c,
                column12: undefined,
                column13: undefined,
                column14: this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.Status__c == 'Sold' ? 'Sold' : (this.comissionData[i].SalesOrder__r && this.comissionData[i].SalesOrder__r.SubStatus__c ? (this.subStatusMapping[this.comissionData[i].SalesOrder__r.SubStatus__c] ? this.subStatusMapping[this.comissionData[i].SalesOrder__r.SubStatus__c] : this.comissionData[i].SalesOrder__r.SubStatus__c) : ''),
                column15: this.comissionData[i].Year__c,
                statusIcon: undefined,
                _children: []
            };
            if (this.comissionData[i].Commission_Line_Items__r) {
                for (let j = 0; j < this.comissionData[i].Commission_Line_Items__r.length; j++) {
                    let cli = this.comissionData[i].Commission_Line_Items__r[j];
                    comissionObj._children.push({
                        column0: cli.Id,
                        column1: '',
                        column2: '',
                        column3: cli.SalesOrder__r ? cli.SalesOrder__r.ProjectName__c : '',
                        column4: (cli.SalesOrder__r && cli.SalesOrder__r.Unit__c) ? cli.SalesOrder__r.Unit__r.Name : '',
                        column5: '',
                        column6: cli.SalesOrder__r ? cli.SalesOrder__r.NetAmount__c : '',
                        column7: cli.OrderDate__c,
                        column8: cli.CommissionAmount__c,
                        column9: cli.CommissionPercentage__c / 100,
                        column10: cli.Status__c,
                        column12: undefined,
                        column13: undefined,
                        column14: cli.SalesOrder__r && cli.SalesOrder__r.Status__c == 'Sold' ? 'Sold' : (cli.SalesOrder__r && cli.SalesOrder__r.SubStatus__c ? (this.subStatusMapping[cli.SalesOrder__r.SubStatus__c] ? this.subStatusMapping[cli.SalesOrder__r.SubStatus__c] : cli.SalesOrder__r.SubStatus__c) : ''),
                    });
                }
            }
            //If not filtered then add
            console.log('comissionObj ', comissionObj);
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
                console.log('comissionObj --> ', comissionObj);
                //add to final list
                this.tableData.push(comissionObj);
                console.log('this.tableData ', this.tableData);
            }
            let filteredData = [];
            if (quarter || year) {
                this.tableData.forEach(element => {
                    console.log('quarter && year', quarter, year, element.column5, element.column15);
                    if (quarter && year) {
                        if (quarter == element.column5 && year == element.column15) {
                            filteredData.push(element);
                        }
                    } else if (quarter && !year) {
                        if (quarter == element.column5) {
                            filteredData.push(element);
                        }
                    } else if (!quarter && year) {
                        if (year == element.column15) {
                            filteredData.push(element);
                        }
                    }
                });
                this.tableData = filteredData;
                console.log('filteredData ', filteredData);
                console.log('this.tableData ', this.tableData);
            }
            console.log('this.tableData ---- > ', this.tableData);
            this.tableData = JSON.parse(JSON.stringify(this.tableData));
        }
    }

    //Poupup Method
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }

    @track toExpandRow = [];
    showPopUpActions = false;
    selectRowID;
    expandCollapseRowsRightSide(event) {
        console.log('event ', event);
        if (this.toExpandRow.length > 0) {
            this.toExpandRow.map((item) => { return item.column0; });
        }
        console.log('this.toExpandRow ', this.toExpandRow);
        console.log('event.detail.row.isExpanded ', event.detail.row.isExpanded);
        console.log('event.detail.row.column0 ', event.detail.row.column0);
        if (this.toExpandRow.indexOf(event.detail.row.column0) == -1 && !event.detail.row.isExpanded) {
            this.toExpandRow.push(event.detail.row.column0);
        } else if (this.toExpandRow.indexOf(event.detail.row.column0) != -1 && event.detail.row.isExpanded) {
            this.toExpandRow.splice(this.toExpandRow.indexOf(event.detail.row.column0), 1);
        }
        console.log('event.detail.action.name ', event.detail.action.name);
        let isSelected = event.detail.action.name;
        if (isSelected == 'Expand') 
        {
            console.log('Inside Expand Click');
            this.expandCollapseRows();
        } 
        else
        {
            console.log('event.detail.action.name ', event.detail.action.name);
            console.log('event.detail.row.column10 ', event.detail.row.column10);
            if (event.detail.row.column10 != 'Not Ready')
            {
                this.showPopUpActions = (event.detail.row.column10 == 'Ready for Submission' || event.detail.row.column10 == 'Fixed');
                this.selectRowID = event.detail.row.column0;
                this.openModal();
            }else
            {
                this.selectRowID = undefined
            }

        }
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

    handleFilerChnageWithDate() {
        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        let quarter;
        let year;
        allSearchFields.forEach(element => {
            console.log('element.name ', element.name, element.value);
            if (element.name == "column3") {
                quarter = element.value;
            } else if (element.name == "column4") {
                year = element.value;
            }
        });
        console.log('quarter', quarter, 'year', year);
        this.buildData(quarter, year);
    }

    clearFilter() {
        this.buildData(undefined, undefined);
        let allSearchFields = this.template.querySelectorAll('.comissionFilters');
        allSearchFields.forEach(element => {
            element.value = '';
        });
    }

    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.isModalOpen = event.detail.isOpen;
    }

    closeModalAndUpdate(event) {
        this.initCommissionRecords();
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.isModalOpen = event.detail.isOpen;
    }

    exportToCSV() {
        let columnHeader = ["Quarter", "Year", "Agency Name ", "Property", "Unit Number", "Net Price", "Order Date", "Comission", "Rate", "Status"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["column5", "column15", "column1", "column3", "column4", "column6", "column7", "column8", "column9", "column10"]; // This array holds the keys in the json data  
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
        downloadLink.download = 'Quarterly Bonus Commission Report.xls.csv';
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