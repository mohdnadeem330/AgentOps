import { LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getSalesReport from '@salesforce/apex/SalesReportConroller.getSalesReport';
import getUserProfileDetails from '@salesforce/apex/UserProfileController.getUserProfileDetails';

export default class SalesReport extends LightningElement {

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    @track data;
    @track sortBy;
    @track sortDirection;
    userData;
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";
    currentPage = 1;
    pageSize = 10;
    @track currentPageData = [];

    tableColumns =
        [
            {
                type: 'text',
                sortable: true,
                fieldName: 'AgentName__c',
                label: 'Agency Name',
                cellAttributes: { class: 'agency-name-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'AccountNumber__c',
                label: 'Agency ID',
                cellAttributes: { class: 'agency-Id-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'AgentType__c',
                label: 'Agency Type',
                cellAttributes: { class: 'agency-type-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'Status__c',
                label: 'Sales Order Status',
                cellAttributes: { class: 'agency-type-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'AccountName__c',
                label: 'Customer Name',
                cellAttributes: { class: 'sales-agent-name-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'UnitAreaUOM__c',
                label: 'Sales UOM',
                cellAttributes: { class: 'sales-uom-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'ProjectName__c',
                label: 'Property Name',
                cellAttributes: { class: 'property-name-cell' /*important for reponsive */ }
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'UnitNumber__c',
                label: 'Unit Number',
                cellAttributes: { class: 'unit-number-cell' /*important for reponsive */ }
            },
            {
                type: 'date',
                sortable: true,
                fieldName: 'CreatedDate',
                label: 'Sales Order Date',
                cellAttributes: { class: 'sales-order-date-cell' /*important for reponsive */ },
                typeAttributes: {
                    day: 'numeric',
                    month: 'numeric',
                    year: 'numeric',
                },
            },
            {
                type: 'text',
                sortable: true,
                fieldName: 'UnitTotalArea__c',
                label: 'Sales Area',
                cellAttributes: { class: 'sales-area-cell' /*important for reponsive */ }
            },
            {
                type: 'number',
                sortable: true,
                fieldName: 'UnitSellingPrice__c',
                label: 'Sales Price',
                cellAttributes: { class: 'sales-price-cell' /*important for reponsive */ }
            },
            {
                type: 'number',
                sortable: true,
                fieldName: 'NetAmount__c',
                label: 'Net Price',
                cellAttributes: { class: 'net-price-cell' /*important for reponsive */ }
            }
        ];

    connectedCallback() {
        this.resetAll();
    }

    async resetAll() {
        let newTableData = [];
        this.userData = await getUserProfileDetails();
        const newData = await getSalesReport({ agentName: this.userData.Account.Name });
        // console.log('newData>>>' + newData);

        for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
        }
        this.data = newTableData;
        this.currentPageData = this.paginatedData();
    }

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.data));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.data = parseData;

    }

    async handleSearch() {
        let account = this.template.querySelector('[data-id="accountField"]');
        let accountValue = account.value;
        let newTableData = [];
        // console.log(accountValue);

        const newData = await getSalesReport({ agentName: this.userData.Account.Name, accountName: accountValue });
        // console.log(JSON.stringify(newData));

        newData.forEach(account => {
            newTableData.push(account);
        });

        this.data = newTableData;
        this.currentPageData = this.paginatedData();
    }

    exportToCSV() {
        let columnHeader = ["Agency Name", "Agency ID", "Agency Type", "Sales Order Status", "Sales Agent Name", "Sales UOM", "Property Name", "Sales Order Date", "Sales Area", "Sales Price"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["AgentName__c", "AccountNumber__c", "AgentType__c", "Status__c", "AccountName__c", "UnitAreaUOM__c", "ProjectName__c", "CreatedDate", "UnitTotalArea__c", "UnitSellingPrice__c"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.data;
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
                    csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';
                } else {
                    csvIterativeData += '""';
                }
                counter++;
            }
            csvIterativeData += newLineCharacter;
        }
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);
        csvIterativeData = csvIterativeData.replace(/"/g, '');

        var downloadLink = document.createElement("a");
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,' + csvIterativeData;
        downloadLink.download = 'Sent Offers.xls.csv';
        downloadLink.click();
    }

    // Pagination : Calculate the total number of pages
    get totalPages() {
        if (this.data != undefined) {
            return Math.ceil(this.data.length / this.pageSize);
        } else {
            return 0;
        }
    }

    // Pagination : Handle "Previous" button click
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            // Update the currentPageData
            this.currentPageData = this.paginatedData();
        }
    }

    // Pagination : Handle "Next" button click
    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            // Update the currentPageData
            this.currentPageData = this.paginatedData();
        }
    }

    // Pagination : Get the current page data
    paginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.data.slice(start, end);
    }

}