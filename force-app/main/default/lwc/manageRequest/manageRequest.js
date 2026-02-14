import { LightningElement, track, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import Id from '@salesforce/user/Id';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import APPROVAL_FIELD from '@salesforce/schema/BrokerRequest__c.ApprovalStatus__c';
import BROKER_REQUEST_OBJECT from '@salesforce/schema/BrokerRequest__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import brokerRequestRecords from "@salesforce/apex/ManageRequestController.brokerRequestRecords";

export default class ManageRequest extends LightningElement {

    @track currentPageMarketing = 1;
    @track currentPageEvent = 1;
    @track pageSize = 5;

    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    // raiseRequestIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";
    @track approvalStatusValue = '';
    @track unfilterBrokerTable = [];
    @track contactId;

    @track approvalStatusField = '';
    @track isModalOpen = false;
    approvalStatusOptions;
    @track showCaseTable = [];
    @track ids;
    @track isViewModalOpen = false;
    @track sortBy;
    @track sortDirection;
    @track typeField = 'Event Request';
    @track displayMarketingFieldsView;
    @track displayEventsFieldsView;
    @track showBrokerRequestTable = [];
    @track displayMarketingFieldsTable = [];
    @track displayEventsFieldsTable = [];
    userId = Id;
    @track Rtype;
    @track recordType;
    @track approvalStatus;
    @track tempData = [];
    @track showSpinner = false;

    connectedCallback() {
        this.displayBrokerRequestTable();
        this.recordType = new URL(window.location.href).searchParams.get("type");
        if (this.recordType != undefined && this.recordType != null && this.recordType != '') {
            this.isModalOpen = true;
        }
    }

    async displayBrokerRequestTable(event) {
        this.showSpinner = true;
        await brokerRequestRecords({
                type : 'Event Request'
            })
            .then(data => {
            this.showBrokerRequestTable = data;
            this.unfilterBrokerTable = data;
            // console.log('  this.showBrokerRequestTable' + JSON.stringify(this.showBrokerRequestTable));
            this.showBrokerRequestTable.forEach(x => {
                // alert('X>>>' + JSON.stringify(x));
                if (x.Type == 'Marketing Reimbursement') {
                    // console.log('87');
                    this.displayMarketingFieldsTable.push(x);
                    this.displayMarketingFieldsView = true;

                } else {
                    // console.log('90');
                    // this.displayEventsFieldsTable=x;
                    this.displayEventsFieldsTable.push(x);
                    this.displayMarketingFieldsView = false;

                }
                this.handleSearchFilter();
            })
            this.showSpinner = false;
            // console.log('*************************8');
            // console.log('displayMarketingFieldsTable' + JSON.stringify(this.displayMarketingFieldsTable));
            // console.log('displayEventsFieldsTable' + JSON.stringify(this.displayEventsFieldsTable));

        }).catch(error => {
            // console.log('error' + JSON.stringify(error));
            this.showSpinner = false;

        });
    }

    // tableMarketingColumns = [
    //     {
    //         type: 'text',
    //         fieldName: 'BrokerRequestNumber',
    //         label: 'Broker Request Number'
    //     }, {
    //         type: 'text',
    //         fieldName: 'Invoice',
    //         label: 'Invoice #'
    //     }, {
    //         type: 'Decimal',
    //         fieldName: 'InvoiceAmount',
    //         label: 'Invoice Amount'
    //     }, {
    //         type: 'Decimal',
    //         fieldName: 'SodicInvoiceAmount',
    //         label: 'Sodic Invoice Amount'
    //     }, {
    //         type: 'Decimal',
    //         fieldName: 'TaxAmount',
    //         label: 'Tax Amount'
    //     }, {
    //         type: 'date',
    //         fieldName: 'InvoiceDate',
    //         label: 'Invoice Date',
    //         sortable: "true"
    //     }, {
    //         type: 'Decimal',
    //         fieldName: 'TotalAmount',
    //         label: 'Total Amount',
    //         sortable: "true"
    //     }, {
    //         type: 'text',
    //         fieldName: 'Attachment',
    //         label: 'Attachments',
    //         sortable: "true"
    //     }, {
    //         type: 'text',
    //         fieldName: 'Comments',
    //         label: 'Comments',
    //         sortable: "true"
    //     }, {
    //         type: 'text',
    //         fieldName: 'ApprovalStatus',
    //         label: 'Approval Status',
    //         sortable: "true"
    //     }, {
    //         label: 'Actions',
    //         fieldName: 'view',
    //         initialWidth: 100,
    //         type: 'button',
    //         typeAttributes: {
    //             iconName: 'action:preview',
    //             name: 'view',
    //             title: 'view',
    //             disabled: false,
    //             value: 'view'
    //         },
    //         cellAttributes: {
    //             class: 'custom-table-icon view-icon',
    //             alignment: `left`
    //         }
    //     }
    // ];

    tableEventColumns = [
        {
            type: 'Name',
            fieldName: 'BrokerRequestNumber',
            label: 'Broker Request Number'
        }, {
            type: 'text',
            fieldName: 'Location',
            label: 'Location'
        }, {
            type: 'date',
            fieldName: 'StartDate',
            label: 'Start Date',
        }, {
            type: 'date',
            fieldName: 'EndDate',
            label: 'End Date',
        }, {
            type: 'text',
            fieldName: 'Comments',
            label: 'Comments',
            sortable: "true"
        }, {
            type: 'text',
            fieldName: 'ApprovalStatus',
            label: 'Approval Status',
            sortable: "true"
        }, {
            label: 'Actions',
            fieldName: 'view',
            initialWidth: 100,
            type: 'button',
            typeAttributes: {
                iconName: 'utility:view',
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

    handleRowAction(event) {
        // console.log('inside row n');
        if (event.detail.action.name === 'view') {
            // console.log(JSON.stringify(event.detail.row));
            this.tempData = event.detail.row;
            // console.log('tempdata*****' + JSON.stringify(this.tempData));

            this.ids = this.tempData.Id;
            this.accountId = this.tempData.Agency;
            this.Rtype = this.tempData.Type;
            this.approvalStatus = this.tempData.ApprovalStatus;
            // console.log('BR>>', this.ids);
            // console.log('rtype>>', this.Rtype);
            this.isViewModalOpen = true;
            // console.log('isViewOopne??' + this.isViewModalOpen);
        }
    }

    handleChangeFields(event) {
        // console.log('inside handle cahnge');
        if (event.target.name == 'type') {
            this.typeField = event.target.value;
            // console.log('418' + this.typeField);
        } if (event.target.name == 'Approval Status') {
            this.approvalStatusField = event.target.value;
            // console.log('appstatus 420>' + this.approvalStatusField);
        }
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
        if (this.recordType != undefined && this.recordType != null && this.recordType != '') {
            window.open('../s/manage-request', '_self');
        }
    }

    @wire(getObjectInfo, { objectApiName: BROKER_REQUEST_OBJECT })
    approvalStatusInfo;

    @wire(getPicklistValues,
        {
            recordTypeId: '$approvalStatusInfo.data.defaultRecordTypeId',
            fieldApiName: APPROVAL_FIELD
        }
    )

    approvalVal({ error, data }) {
        if (data) {
            this.approvalStatusOptions = data.values;
            // console.log('approvalStatusOptions>>>>', this.approvalStatusOptions);
        } if (error) {
            // console.log('error>>>>', error);
        }
    }

    typeFilter(event) {
        this.typeField = event.currentTarget.value;
        // console.log('selected type>>' + this.typeField);
        // this.selecteddoctype =   this.type;
        /* if(this.typeField=="Event Request"){
                   this.displayMarketingFieldsView= false;
                   // console.log('displayMarketingFieldsView type>>'+ this.displayMarketingFieldsView);
         }else{
                     this.displayMarketingFieldsView= true;
                     // console.log('displayMarketingFieldsView type>>'+ this.displayMarketingFieldsView);
          }
          this.displayBrokerRequestTable();*/
    }

    @wire(getObjectInfo, { objectApiName: BROKER_REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            const err = error;
            // console.log('error>>>>>' + JSON.stringify(err));
        } else if (data) {
            // console.log('############');
            const rtis = data.recordTypeInfos;
            // console.log('rtis' + JSON.stringify(rtis));
            this.eventRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Event Requests');
            this.marketingRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Marketing Reimbursement');
            // console.log('event' + this.eventRT);
            // console.log('this.marketingRTpe' + this.marketingRT);
        }
    };

    get options() {
        return [
            { label: 'Event Request', value: 'Event Request' }
            // { label: 'Marketing Reimbursement', value: 'Marketing Reimbursement' }
        ];
    }

    async handleSearchFilter(event) {
        let temporaryData = [];
        // console.log('this.typeField' + this.typeField);
        // console.log('this.approval stts' + this.approvalStatusField);
        this.unfilterBrokerTable.forEach(x => {
            // console.log('unfilter>>>>>>' + JSON.stringify(x));
            let isTrue = true;
            if (isTrue && this.typeField != '' && this.typeField != x.Type) {
                isTrue = false;
            }
            if (isTrue && this.approvalStatusField != '' && this.approvalStatusField != x.ApprovalStatus) {
                isTrue = false;
            }

            if (isTrue) {
                temporaryData.push(x);
            }
            //  this.unfilterCaseTable.push(tempData);

        })
        // console.log('tempData' + JSON.stringify(temporaryData));

        if (this.typeField == 'Marketing Reimbursement') {
            // console.log('581>>');
            this.displayMarketingFieldsView = true;
            this.displayMarketingFieldsTable = temporaryData;
            // console.log('571' + this.displayMarketingFieldsView);
        } else {
            this.displayMarketingFieldsView = false;
            this.displayEventsFieldsTable = temporaryData;
            // console.log('624' + JSON.stringify(this.displayEventsFieldsTable));
            this.displayBrokerRequestTable();
        }
    }

    displayEventTable(event) {
        // console.log('parent 587');
        this.displayMarketingFieldsView = event.detail;
        this.displayBrokerRequestTable();
    }

    typeChangeEvent(event) {
        // console.log('type change 606');
        this.typeField = event.detail;
    }

    clearFilter() {
        this.approvalStatusField = '';
        this.typeField = 'Marketing Reimbursement';
        // this.displayBrokerRequestTable();
        this.displayMarketingFieldsView = true;
        // this.displayMarketingFieldsTable ;
    }

    showTable(event) {
        this.displayMarketingFieldsView = event.detail;
    }

    exportToCSV() {
        // console.log('inside export');
        let columnHeader = ["Broker Request Number", "Location", "Start Date", "End Date", "Comments", "Approval Status", "Invoice", "Invoice Date", "Invoice Amount", "Tax Amount", "Total Amount", "Attachments"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["BrokerRequestNumber", "Location", "StartDate", "EndDate", "Comments", "ApprovalStatus", "Invoice", "InvoiceDate", "InvoiceAmount", "TaxAmount", "TotalAmount", "Attachment"];  // This array holds the keys in the json data  
        var jsonRecordsData = this.showBrokerRequestTable;
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
        downloadLink.download = 'Raise Request.xls.csv';
        downloadLink.click();
    }
    get tempDataLength(){
        return this.displayEventsFieldsTable.length == 0;
    }

    // Calculate the total number of pages for Marketing table
    get totalPagesMarketing() {
        if (this.displayMarketingFieldsTable) {
            return Math.ceil(this.displayMarketingFieldsTable.length / this.pageSize);
        }
        return 0;
    }

    // Calculate the total number of pages for Event table
    get totalPagesEvent() {
        if (this.displayEventsFieldsTable) {
            return Math.ceil(this.displayEventsFieldsTable.length / this.pageSize);
        }
        return 0;
    }

    // Handle Previous button click for Marketing table
    handlePreviousMarketing() {
        if (this.currentPageMarketing > 1) {
            this.currentPageMarketing--;
        }
    }

    // Handle Next button click for Marketing table
    handleNextMarketing() {
        if (this.currentPageMarketing < this.totalPagesMarketing) {
            this.currentPageMarketing++;
        }
    }

    // Handle Previous button click for Event table
    handlePreviousEvent() {
        if (this.currentPageEvent > 1) {
            this.currentPageEvent--;
        }
    }

    // Handle Next button click for Event table
    handleNextEvent() {
        if (this.currentPageEvent < this.totalPagesEvent) {
            this.currentPageEvent++;
        }
    }

    // Slice the data for the current page for Marketing table
    get paginatedDataMarketing() {
        const start = (this.currentPageMarketing - 1) * this.pageSize;
        const end = start + this.pageSize;
        if (!this.displayMarketingFieldsTable) {
            return [];
        } else {
            return this.displayMarketingFieldsTable.slice(start, end);
        }
    }

    // Slice the data for the current page for Event table
    get paginatedDataEvent() {
        const start = (this.currentPageEvent - 1) * this.pageSize;
        const end = start + this.pageSize;
        if (!this.displayEventsFieldsTable) {
            return [];
        } else {
            return this.displayEventsFieldsTable.slice(start, end);
        }
    }
}