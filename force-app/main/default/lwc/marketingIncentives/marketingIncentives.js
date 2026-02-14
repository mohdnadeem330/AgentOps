import { LightningElement, track, wire } from 'lwc';
import BROKER_REQUEST_OBJECT from '@salesforce/schema/BrokerRequest__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import brokerRequestRecords from "@salesforce/apex/ManageRequestController.brokerRequestRecords";

export default class MarketingIncentives extends LightningElement {

    @track currentPageMarketing = 1;
    @track currentPageEvent = 1;
    @track pageSize = 5;
    @track isViewModalOpen = false;
    @track typeField = 'Marketing Reimbursement';
    @track displayMarketingFieldsView;
    @track showBrokerRequestTable = [];
    @track displayMarketingFieldsTable = [];
    @track recordType;
    @track tempData = [];
    @track showSpinner = false;
    @track brokerRequestId;
    enableAction = false;

    connectedCallback() {
        this.displayBrokerRequestTable();
        this.recordType = new URL(window.location.href).searchParams.get("type");
    }

    async displayBrokerRequestTable(event) {
        this.showSpinner = true;
        await brokerRequestRecords({
            type : 'Marketing Reimbursement'
        }).then(data => {
            this.showBrokerRequestTable = data;

            this.showBrokerRequestTable.forEach(x => {
                if (x.Type == 'Marketing Reimbursement') {
                    this.displayMarketingFieldsTable.push(x);
                    this.displayMarketingFieldsView = true;
                } 
            })
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
        });
    }

    handleRowAction(event) {
        if (event.detail.action.name === 'view') {
            this.tempData = event.detail.row;
            this.brokerRequestId = this.tempData.Id;
            this.isViewModalOpen = true;
            this.enableAction = (this.tempData.invoiceStatus == 'Fixed' || this.tempData.invoiceStatus == 'Ready for Submission') ? true : false;
        }
    }

    closeModal(event) {
        this.isViewModalOpen = event.detail.isOpen;
    }

    @wire(getObjectInfo, { objectApiName: BROKER_REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            const err = error;
        } else if (data) {
            const rtis = data.recordTypeInfos;
            this.marketingRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Marketing Reimbursement');
           
        }
    };

    showTable(event) {
        this.displayMarketingFieldsView = event.detail;
    }

    // Calculate the total number of pages for Marketing table
    get totalPagesMarketing() {
        if (this.displayMarketingFieldsTable) {
            return Math.ceil(this.displayMarketingFieldsTable.length / this.pageSize);
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

    tableMarketingColumns = [
        {
            type: 'text',
            fieldName: 'BrokerRequestNumber',
            label: 'Broker Request Number'
        }, {
            type: 'Decimal',
            fieldName: 'InvoiceAmount',
            label: 'Invoice Amount'
        }, {
            type: 'Decimal',
            fieldName: 'TaxAmount',
            label: 'Tax Amount'
        }, {
            type: 'date',
            fieldName: 'InvoiceDate',
            label: 'Invoice Date',
            sortable: "true"
        }, {
            type: 'Decimal',
            fieldName: 'TotalAmount',
            label: 'Total Amount',
            sortable: "true"
        },{
            type: 'text',
            fieldName: 'requestedQuarter',
            label: 'Quarter',
            sortable: "true"
        },{
            type: 'text',
            fieldName: 'requestYear',
            label: 'Year',
            sortable: "true"
        },{
            type: 'text',
            fieldName: 'invoiceStatus',
            label: 'Invoice Status',
            sortable: "true"
        },{
            type: 'text',
            fieldName: 'ApprovalStatus',
            label: 'Approval Status',
            sortable: "true"
        },{
            type: 'text',
            fieldName: 'Comments',
            label: 'Comments',
            sortable: "true"
        },
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
}