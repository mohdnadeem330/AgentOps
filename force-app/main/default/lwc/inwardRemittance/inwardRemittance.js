import { LightningElement, track, wire } from 'lwc';
import getInwardRemittances from '@salesforce/apex/InwardRemittanceController.getInwardRemittances';
import getProjects from '@salesforce/apex/InwardRemittanceController.getProjects';
import updateRemittanceStatus from '@salesforce/apex/InwardRemittanceController.updateRemittanceStatus';
import getExistingReceipts from '@salesforce/apex/InwardRemittanceController.getExistingReceipts';
import linkReceiptToRemittance from '@salesforce/apex/InwardRemittanceController.linkReceiptToRemittance';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import INWARD_REMITTANCE_OBJECT from '@salesforce/schema/Inward_Remittance__c';
import TRANSFER_TYPE_FIELD from '@salesforce/schema/Inward_Remittance__c.Transfer_Type__c';
import BANK_FIELD from '@salesforce/schema/Inward_Remittance__c.Bank__c';
import STATUS_FIELD from '@salesforce/schema/Inward_Remittance__c.Status__c';
import RECEIPT_ACKNOWLEDGEMENT_OBJECT from '@salesforce/schema/ReceiptAcknowledgement__c';
import RECEIPT_STATUS_FIELD from '@salesforce/schema/ReceiptAcknowledgement__c.Status__c';

export default class InwardRemittance extends NavigationMixin(LightningElement) {
    @track remittances = [];
    @track virtualAccountNumber = '';
    @track realAccountNumber = '';
    @track bank = '';
    @track transferType = '';
    @track amount = null;
    @track paymentDetails = '';
    @track startDate = null;
    @track endDate = null;
    @track project = '';
    @track unit = '';
    @track salesOrder = '';
    @track status = 'Unprocessed';
    @track receiptStatus = '';
    @track projectOptions = [];
    @track pageSize = 20;
    @track currentPage = 1;
    @track totalPages = 0;
    @track totalRecords = 0;
    @track showReceiptModal = false;
    @track selectedRemittanceId;
    @track wiredRemittanceResult;
    @track error;
    @track displayedColumns;
    @track currentDisplayStatus = 'Unprocessed';
    @track showReceiptStatusFilter = false;

    // Add new properties for existing receipts functionality
    @track showExistingReceiptsModal = false;
    @track selectedReceiptId;
    @track existingReceipts = [];
    @track selectedRows = [];

    @wire(getObjectInfo, { objectApiName: RECEIPT_ACKNOWLEDGEMENT_OBJECT })
    receiptObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$receiptObjectInfo.data.defaultRecordTypeId', fieldApiName: RECEIPT_STATUS_FIELD })
    receiptStatusPicklist;

    get receiptStatusOptions() {
        return this.receiptStatusPicklist.data
            ? [{ label: 'None', value: '' }, ...this.receiptStatusPicklist.data.values]
            : [];
    }

    get columns() {
        const baseColumns = [
            { 
                label: 'Name',
                fieldName: 'remittanceUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'name' },
                    target: '_blank'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            },
            { label: 'Virtual Account Number', fieldName: 'virtualAccountNumber', type: 'text' },
            { label: 'Real Account Number', fieldName: 'realAccountNumber', type: 'text' },
            { label: 'Bank', fieldName: 'bank', type: 'text' },
            { label: 'Transfer Type', fieldName: 'transferType', type: 'text' },
            { label: 'Amount', fieldName: 'amount', type: 'currency' },
            { label: 'Payment Details', fieldName: 'paymentDetails', type: 'text' },
            { label: 'Transaction Reference', fieldName: 'transactionReference', type: 'text' },
            { label: 'Customer Reference', fieldName: 'customerReference', type: 'text' },
            { label: 'Payment Status', fieldName: 'paymentStatus', type: 'text' },
            { 
                label: 'Project',
                fieldName: 'projectUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'projectName' },
                    target: '_blank'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            },
            { 
                label: 'Unit', 
                fieldName: 'unitUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'unitName' },
                    target: '_blank'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            },
            { 
                label: 'Sales Order', 
                fieldName: 'salesOrderUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'salesOrderName' },
                    target: '_blank'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            },
            {
                label: 'Customer Name',
                fieldName: 'customerUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'customerName' },
                    target: '_blank'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            }
        ];

        if (this.currentDisplayStatus === 'Processed') {
            baseColumns.push({
                label: 'Receipt',
                fieldName: 'receiptUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'receiptName' },
                    target: '_blank'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            },
            {
                label: 'Receipt Status',
                fieldName: 'receiptStatus',
                type: 'text',
                cellAttributes: {
                    alignment: 'left'
                }
            },
            {
                label: 'Unidentified Receipt',
                fieldName: 'isUnidentifiedReceipt',
                type: 'boolean'
            });
        }

        if (this.currentDisplayStatus !== 'Processed') {
            baseColumns.push({
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: 'Create Receipt', name: 'create_receipt' },
                        { label: 'Mark as Existing', name: 'mark_existing' }
                    ]
                }
            });
        }

        return baseColumns;
    }

    receiptColumns = [
        { 
            label: 'Receipt Number',
            fieldName: 'receiptUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'name' },
                target: '_blank'
            }
        },
        { label: 'Amount', fieldName: 'amount', type: 'currency' },
        { label: 'Maturity Date', fieldName: 'maturityDate', type: 'date' },
        { label: 'Status', fieldName: 'status', type: 'text' }
    ];

    @wire(getObjectInfo, { objectApiName: INWARD_REMITTANCE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TRANSFER_TYPE_FIELD })
    transferTypePicklist;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BANK_FIELD })
    bankPicklist;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    statusPicklist;

    @wire(getProjects)
    wiredProjects({ error, data }) {
        if (data) {
            this.projectOptions = data.map(project => ({
                label: project.Name,
                value: project.Name
            }));
        }
    }

    get transferTypeOptions() {
        return this.transferTypePicklist.data 
            ? [{ label: 'None', value: '' }, ...this.transferTypePicklist.data.values]
            : [];
    }

    get bankOptions() {
        return this.bankPicklist.data
            ? [{ label: 'None', value: '' }, ...this.bankPicklist.data.values]
            : [];
    }

    get statusOptions() {
        return this.statusPicklist.data
            ? this.statusPicklist.data.values
            : [];
    }

    get isLinkButtonDisabled() {
        return !this.selectedReceiptId;
    }

    connectedCallback() {
        this.displayedColumns = this.columns;
        this.loadData();
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
        
        // Reset showReceiptStatusFilter when status changes
        if (field === 'status') {
            this.showReceiptStatusFilter = false;
            this.receiptStatus = '';
        }
    }

    handleSearch() {
        this.currentDisplayStatus = this.status;
        this.displayedColumns = this.columns;
        this.showReceiptStatusFilter = this.status === 'Processed';
        this.currentPage = 1;
        this.loadData();
    }

    handleClearFilters() {
        this.virtualAccountNumber = '';
        this.realAccountNumber = '';
        this.bank = '';
        this.transferType = '';
        this.amount = null;
        this.paymentDetails = '';
        this.startDate = null;
        this.endDate = null;
        this.project = '';
        this.unit = '';
        this.salesOrder = '';
        this.status = 'Unprocessed';
        this.receiptStatus = '';
        this.currentPage = 1;
        this.currentDisplayStatus = 'Unprocessed';
        this.displayedColumns = this.columns;
        this.showReceiptStatusFilter = false;
        this.loadData();
    }

    handleExport() {
        // Get the datatable element
        const table = this.template.querySelector('lightning-datatable');
        if (!table || !this.remittances.length) {
            this.showToast('Error', 'No data to export', 'error');
            return;
        }

        // Create CSV data
        let csvData = [];
        
        // Add headers (excluding action column)
        const headers = this.columns
            .filter(col => col.type !== 'action')
            .map(col => col.label);
        csvData.push(headers);

        // Add data rows
        this.remittances.forEach(record => {
            const row = this.columns
                .filter(col => col.type !== 'action')
                .map(col => {
                    let value = '';
                    if (col.type === 'url') {
                        // For URL fields, use the display label instead of the URL
                        value = record[col.typeAttributes.label.fieldName] || '';
                    } else if (col.type === 'currency') {
                        // Format currency values
                        value = record[col.fieldName] ? 
                            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
                                .format(record[col.fieldName]) : '';
                    } else if (col.type === 'date') {
                        // Format date values
                        value = record[col.fieldName] ? new Date(record[col.fieldName]).toLocaleDateString() : '';
                    } else {
                        value = record[col.fieldName] || '';
                    }
                    // Escape special characters and wrap in quotes if needed
                    return `"${value.toString().replace(/"/g, '""')}"`;
                });
            csvData.push(row);
        });

        // Convert to CSV string
        const csv = csvData.map(row => row.join(',')).join('\n');

        // Create and trigger download
        const downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        downloadElement.target = '_self';
        downloadElement.download = 'Inward_Remittances_' + new Date().toISOString().slice(0,10) + '.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
        document.body.removeChild(downloadElement);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        switch (actionName) {
            case 'create_receipt':
                this.selectedRemittanceId = row.id;
                this.showReceiptModal = true;
                break;
            case 'mark_existing':
                this.selectedRemittanceId = row.id;
                this.showExistingReceiptsModal = true;
                this.loadExistingReceipts(row.id); 
                break;
        }
    }

    async loadData() {
        try {
            const result = await getInwardRemittances({
                virtualAccountNumber: this.virtualAccountNumber,
                virtualAccountIBAN: this.virtualAccountIBAN,
                realAccountNumber: this.realAccountNumber,
                bank: this.bank,
                transferType: this.transferType,
                amount: this.amount,
                paymentDetails: this.paymentDetails,
                startDate: this.startDate,
                endDate: this.endDate,
                project: this.project,
                unit: this.unit,
                salesOrder: this.salesOrder,
                status: this.status,
                receiptStatus: this.receiptStatus,
                pageSize: this.pageSize,
                pageNumber: this.currentPage
            });
            
            this.remittances = result.records.map(record => {
                return {
                    ...record,
                    name: record.name || '',
                    remittanceUrl: record.id ? `/lightning/r/Inward_Remittance__c/${record.id}/view` : '',
                    projectName: record.projectName || '',
                    projectUrl: record.projectUrl || '',
                    unitName: record.unitName || '',
                    unitUrl: record.unitUrl || '',
                    salesOrderName: record.salesOrderName || '',
                    salesOrderUrl: record.salesOrderUrl || '',
                    customerName: record.customerName || '',
                    customerUrl: record.customerUrl || '',
                    receiptName: record.receiptName || '',
                    receiptUrl: record.receiptUrl || '',
                    receiptStatus: record.receiptStatus || '',
                    isUnidentifiedReceipt: record.isUnidentifiedReceipt
                };
            });
            
            this.totalRecords = result.totalRecords;
            this.totalPages = result.totalPages;
            this.error = undefined;
        } catch (error) {
            this.error = error.body?.message || 'Unknown error occurred';
            this.showToast('Error', this.error, 'error');
        }
    }

    async loadExistingReceipts(remittanceId) {
        try {
            this.existingReceipts = await getExistingReceipts({ remittanceId });
            this.existingReceipts = this.existingReceipts.map(receipt => ({
                ...receipt,
                receiptUrl: `/lightning/r/Receipt_Acknowledgement__c/${receipt.id}/view`
            }));
        } catch (error) {
            this.showToast('Error', 'Failed to load existing receipts', 'error');
        }
    }

    handleReceiptSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedReceiptId = selectedRows.length ? selectedRows[0].id : null;
        this.selectedRows = selectedRows;
    }

    async handleLinkReceipt() {
        try {
            await linkReceiptToRemittance({
                remittanceId: this.selectedRemittanceId,
                receiptId: this.selectedReceiptId
            });
            
            this.showToast('Success', 'Receipt linked successfully', 'success');
            this.closeExistingReceiptsModal();
            await this.loadData();
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error linking receipt', 'error');
        }
    }

    handleReceiptModalClose() {
        this.showReceiptModal = false;
        if (this.selectedRemittanceId) {
            this.updateStatus(this.selectedRemittanceId, 'Processed');
            this.selectedRemittanceId = null;
        }
    }

    closeExistingReceiptsModal() {
        this.showExistingReceiptsModal = false;
        this.selectedReceiptId = null;
        this.selectedRemittanceId = null;
        this.existingReceipts = [];
        this.selectedRows = [];
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadData();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadData();
        }
    }

    async updateStatus(remittanceId, status) {
        try {
            await updateRemittanceStatus({ remittanceId, status });
            this.showToast('Success', 'Status updated successfully', 'success');
            await this.loadData();
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error updating status', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}