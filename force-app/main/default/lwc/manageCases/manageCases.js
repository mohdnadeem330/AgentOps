import { LightningElement, track, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import displayCaseRecords from "@salesforce/apex/ManageCasesController.displayCaseRecords";
import Id from '@salesforce/user/Id';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CATEGORY_FIELD from '@salesforce/schema/Case.Category__c';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';


export default class ManageCases extends LightningElement {
    currentPage = 1;
    pageSize = 5;

    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    raiseRequestIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";;
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";

    @track contactId;
    @track visibleSpinner;
    @track isModalOpen = false;
    @track showCaseTable = [];
    @track ids;
    @track isViewModalOpen = false;
    @track sortBy;
    @track sortDirection;
    @track categoryField = '';
    @track statusField = '';
    userId = Id;
    @track catgoryvalue = '';
    categoryOptions;
    @track statusvalue = '';
    statusOptions;
    @track searchBy = '';
    @track unfilterCaseTable = [];
    @track showSpinner = false;
    tableColumns = [
        {
            type: 'text',
            fieldName: 'Subject',
            label: 'Subject',
            // initialWidth: 200,
        },
        {
            type: 'text',
            fieldName: 'Category',
            label: 'Category',
        },
        {
            type: 'text',
            fieldName: 'Attachment',
            label: 'Attachments',
        },
        {
            type: 'date',
            fieldName: 'RequestedDate',
            label: 'Requested Date',
            sortable: "true"
        },
        {
            type: 'text',
            fieldName: 'ReferenceNumber',
            label: 'Reference Number'

        },
        {
            label: 'Status',
            // initialWidth: 100,
            fieldName: 'Status',
            type: 'text'
            /* cellAttributes: {
                 iconName: { fieldName: 'statusIcon' },
                 iconPosition: 'left',
             }*/

        }
        ,
        {

            label: 'Actions',
            fieldName: 'view',
            initialWidth: 100,
            type: 'button',
            typeAttributes: {
                iconName: 'action:preview',

                name: 'view',
                title: 'view',
                disabled: false,
                value: 'view'

            },

            cellAttributes: {
                class: 'custom-table-icon view-icon',
                alignment: `left`
            }
        }


    ];

    connectedCallback() {

        this.getData();
    }


    async getData(event) {
        this.showSpinner = true;
        await displayCaseRecords({ userId: this.userId, whereClause: this.whereClause }).then(result => {
            this.showCaseTable = result;
            this.unfilterCaseTable = result;

            this.showSpinner = false;

        }).catch(error => {
            this.error = error;
            console.log('err>>' + JSON.stringify(this.error));
            this.showSpinner = false;
        })
    }

    handleRowAction(event) {

        if (event.detail.action.name === 'view') {

            var tempData = event.detail.row;
            this.ids = tempData.Id;
            this.isViewModalOpen = true;

        }
        // if you have multiple actions you can use the switch case.
    }

    exportToCSV() {
        let columnHeader = ["Subject", "Category", "Attachments", "Requested Date", "Reference Number", "Status"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["Subject", "Category", "Attachment", "RequestedDate", "ReferenceNumber", "Status"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.showCaseTable;
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
        downloadLink.download = 'Raise Cases.xls.csv';
        downloadLink.click();
    }


    handleSortCaseData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortCaseData(event.detail.fieldName, event.detail.sortDirection);
    }


    sortCaseData(fieldname, direction) {

        let parseData = JSON.parse(JSON.stringify(this.showCaseTable));

        let keyValue = (a) => {
            return a[fieldname];
        };


        let isReverse = direction === 'asc' ? 1 : -1;


        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });

        this.showCaseTable = parseData;


    }



    raiseRequest() {
        this.openModal();
    }
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal(event) {

        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.isModalOpen = event.detail.isOpen;
        this.isViewModalOpen = event.detail.isOpen;


    }


    //GETTING CATEGORY PICKLIST VALUES
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    categoryInfo;

    @wire(getPicklistValues,
        {
            recordTypeId: '$categoryInfo.data.defaultRecordTypeId',
            fieldApiName: CATEGORY_FIELD

        }
    )

    categoryval({ error, data }) {
        if (data) {

            this.categoryOptions = data.values;

        } if (error) {
            console.log('error>>>>', error);
        }
    }

    //get status value
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    statusInfo;

    @wire(getPicklistValues,
        {
            recordTypeId: '$categoryInfo.data.defaultRecordTypeId',
            fieldApiName: STATUS_FIELD

        }
    )

    statusval({ error, data }) {
        if (data) {

            this.statusOptions = data.values;

        } if (error) {
            console.log('error>>>>', error);
        }
    }

    handleChangeFields(event) {
        if (event.target.name == 'Category') {
            this.categoryField = event.target.value;
        } if (event.target.name == 'Status') {
            this.statusField = event.target.value;
        } if (event.target.name == 'Searchby') {
            this.searchBy = event.target.value;
        }
    }

    @track tempData;

    //Filter logic
    async handleSearchCases(event) {
        let tempData = [];

        this.unfilterCaseTable.forEach(x => {
            let isTrue = true;
            if (isTrue && this.categoryField != '' && this.categoryField != x.Category) {
                isTrue = false;

            }
            if (isTrue && this.statusField != '' && this.statusField != x.Status) {
                isTrue = false;
            }
            if (isTrue && this.searchBy != '' && (!(((x.Subject).toLowerCase().includes(this.searchBy.toLowerCase())) || (x.ReferenceNumber).includes(this.searchBy)))) {
                //|| !(x.Subject).includes(this.searchBy)
                isTrue = false;
            }
            if (isTrue) {
                tempData.push(x);


            }
            //  this.unfilterCaseTable.push(tempData);

        })
        this.showCaseTable = tempData;




    }

    clearFilter() {
        let allSearchFields = this.template.querySelectorAll('.casefilters');
        for (let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value = '';
        }
        this.getData();
    }
    get showCaseTableSize() {
        return this.showCaseTable.length == 0;
    }

    // Add a method to calculate the total number of pages:
    get totalPages() {
        if (this.showCaseTable) {
            return Math.ceil(this.showCaseTable.length / this.pageSize);
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
        if (!this.showCaseTable) {
            return [];
        } else {
            return this.showCaseTable.slice(start, end);
        }
    }
}