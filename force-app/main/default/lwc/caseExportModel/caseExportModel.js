import { LightningElement, track, wire } from 'lwc';
import getFilteredCases from '@salesforce/apex/North_baniyasRequest.getFilteredCasesForExport';

import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

export default class CaseExportModal extends LightningElement {
    @track status;
    @track selectedCategory;
    @track selectedSubCategory;
    @track selectedPriority;
    @track fromDate;
    @track toDate;
    @track cases = [];

    @track categoryOptions = [];
    @track subCategoryOptions = [{ label: '--None--', value: null }];
    @track priorityOptions = [];

    recordTypeId;
    controllerValues = {}; // controller mapping for dependent picklist
    allSubCategoryMap = []; // all subcategories
    @track noRecordsFound = false; 
    @track errorMessage = '';

    statusOptions = [
        { label: '--None--', value: null },
        { label: 'New', value: 'New' },
        { label: 'Work In Progress', value: 'Work In Progress' },
        { label: 'Escalated', value: 'Escalated' },
        { label: 'Re Opened', value: 'Re Opened' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Closed', value: 'Closed' }
    ];

    // Get Record Type ID
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    handleObjectInfo({ data, error }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            for (const rtId in rtis) {
                if (rtis[rtId].name === 'Requests') {
                    this.recordTypeId = rtId;
                    console.log('✅ RecordTypeID:', rtId);
                    break;
                }
            }
        } else if (error) {
            console.error('❌ Error fetching object info:', error);
        }
    }

    // Get all picklists via record type
    @wire(getPicklistValuesByRecordType, {
        objectApiName: CASE_OBJECT,
        recordTypeId: '$recordTypeId'
    })
    picklistHandler({ data, error }) {
        if (data) {
            const allCategories = data.picklistFieldValues.CaseCategory__c.values;
            const subCategoryField = data.picklistFieldValues.SubCategory__c;
            const priorityField = data.picklistFieldValues.Priority;

            this.allSubCategoryMap = subCategoryField.values;
            this.controllerValues = subCategoryField.controllerValues;

            this.categoryOptions = [
                { label: '--None--', value: null },
                ...allCategories.filter(item =>
                    item.label.toLowerCase().startsWith('north')
                )
            ];

            this.priorityOptions = [
                { label: '--None--', value: null },
                ...priorityField.values.map(item => ({
                    label: item.label,
                    value: item.value
                }))
            ];

            console.log('✅ Categories:', this.categoryOptions);
            console.log('✅ Subcategories:', this.allSubCategoryMap);
        } else if (error) {
            console.error('❌ Error loading picklist values:', error);
        }
    }

    // Handle changes
    handleChange(event) {
        const { name, value } = event.target;

        if (name === 'status') {
            this.status = value;
        } else if (name === 'category') {
            this.handleCategoryChange(value);
        } else if (name === 'subCategory') {
            this.selectedSubCategory = value;
        } else if (name === 'priority') {
            this.selectedPriority = value;
        } else if (name === 'fromDate') {
            this. fromDate = value;
        } else if (name === 'toDate') {
            this.toDate = value;
        }
        console.log('From Date-->',this.fromDate);
        console.log('To Date-->',this.toDate);
    }

    handleCategoryChange(selectedCategory) {
        this.selectedCategory = selectedCategory;
        this.selectedSubCategory = null;

        const controllerKey = this.controllerValues[this.selectedCategory];
        console.log('🔍 Controller Key for selected category:', controllerKey);

        if (controllerKey === undefined) {
            this.subCategoryOptions = [{ label: '--None--', value: null }];
            return;
        }

        const filtered = this.allSubCategoryMap
            .filter(item => item.validFor.includes(controllerKey))
            .map(item => ({
                label: item.label,
                value: item.value
            }));

        this.subCategoryOptions = [
            { label: '--None--', value: null },
            ...filtered
        ];

        console.log('✅ Filtered Subcategories:', this.subCategoryOptions);
    }

    // Fetch filtered case data
    handleSearch() {
        this.errorMessage = '';
        this.noRecordsFound = false;

        // Validate dates
        const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

        if ((this.fromDate && this.fromDate > today) || (this.toDate && this.toDate > today)) {
            this.errorMessage = 'From Date and To Date cannot be in the future.';
            this.cases = [];
            return; // stop further execution
        }

        getFilteredCases({
            status: this.status,
            priority: this.selectedPriority,
            category: this.selectedCategory,
            subCategory: this.selectedSubCategory,
            fromDate: this.fromDate,
            toDate: this.toDate
        })
            .then(result => {
                if (result.length === 0) {
                    this.noRecordsFound = true;
                    this.cases = [];
                } else {
                    this.noRecordsFound = false;
                    this.cases = result.map(row => {
                        const c = row.caseRecord; // actual Case
                        return {
                            Id: c.Id,
                            CaseNumber: c.CaseNumber,
                            Subject: c.Subject,
                            Origin: c.Origin,
                            OwnerName: c.Owner?.Name || '',
                            Assigned_To__r: c.Assigned_To__r,
                            Account: c.Account,
                            Contact: c.Contact,
                            CustomerType__c: c.CustomerType__c,
                            SuppliedName: c.SuppliedName,
                            SuppliedEmail: c.SuppliedEmail,
                            SuppliedPhone: c.SuppliedPhone,
                            Recordtype_Name__c: c.Recordtype_Name__c,
                            Priority: c.Priority,
                            CaseCategory__c: c.CaseCategory__c,
                            SubCategory__c: c.SubCategory__c,
                            Unit_Name__c: c.Unit_Name__c,
                            Status: c.Status,
                            Appointment_Date__c: c.Appointment_Date__c,
                            CreatedBy: c.CreatedBy,
                            CreatedDate: c.CreatedDate,
                            LastModifiedBy: c.LastModifiedBy,
                            LastModifiedDate: c.LastModifiedDate,
                            ClosedDate: c.ClosedDate,
                            LastComment: row.lastComment || '',
                            CaseComment: c.CaseComments__c
                        };
                    });
                }
            })
            .catch(error => {
                console.error('❌ Error fetching cases:', JSON.stringify(error));
                this.cases = [];
                this.noRecordsFound = false;
                if (error.body && error.body.message) {
                    this.errorMessage = error.body.message;
                } else if (error.message) {
                    this.errorMessage = error.message;
                } else {
                    this.errorMessage = 'Unknown error occurred while fetching cases.';
                }
            });
    }

    // Export to CSV
    handleExport() {
        if (!this.cases.length) return;

        let csv = 'Case Number,Subject,Status,Priority,Origin,Owner,Assigned To,Account,Contact,Customer Type,Web Name,Web Email,Web Phone,Record Type,Category,Sub Category,Unit,Appointment Date,Appointment Time,Created By,Created Date,'+
					'Last Modified By,Last Modified Date,Closed Date,Customer Comment,Last Comment\n';
        this.cases.forEach(row => {
            csv += [
                this.escapeCsv(row.CaseNumber),
                this.escapeCsv(row.Subject),
                this.escapeCsv(row.Status),
                this.escapeCsv(row.Priority),
                this.escapeCsv(row.Origin),
                this.escapeCsv(row.OwnerName),
                this.escapeCsv(row.Assigned_To__r?.Name),
                this.escapeCsv(row.Account?.Name),
                this.escapeCsv(row.Contact?.Name),
                this.escapeCsv(row.CustomerType__c),
                this.escapeCsv(row.SuppliedName),
                this.escapeCsv(row.SuppliedEmail),
                this.escapeCsv(row.SuppliedPhone),
                this.escapeCsv(row.Recordtype_Name__c),
                this.escapeCsv(row.CaseCategory__c),
                this.escapeCsv(row.SubCategory__c),
                this.escapeCsv(row.Unit_Name__c),
                this.escapeCsv(this.formatDate(row.Appointment_Date__c)), // for date
                this.escapeCsv(this.formatTime(row.Appointment_Date__c)),
                this.escapeCsv(row.CreatedBy.Name),
                this.escapeCsv(row.CreatedDate),
                this.escapeCsv(row.LastModifiedBy.Name),
                this.escapeCsv(row.LastModifiedDate),
                this.escapeCsv(row.ClosedDate),
                this.escapeCsv(row.CaseComment),
                this.escapeCsv(row.LastComment)
            ].join(",") + "\n";
        });

        const csvContent = btoa(
            new TextEncoder().encode(csv).reduce((data, byte) => data + String.fromCharCode(byte), '')
        );

        const link = document.createElement('a');
        link.href = `data:text/csv;base64,${csvContent}`;
        link.download = 'Cases_Export.csv';

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    // Close the modal
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    escapeCsv(value) {
        if (!value) return '';
        let str = value.toString().replace(/"/g, '""'); // double quotes escape
        return `"${str}"`; // wrap in quotes
    }

    formatDate(dateTimeStr) {
        if (!dateTimeStr) return '';
        const dt = new Date(dateTimeStr);
        return dt.toISOString().split('T')[0]; // returns YYYY-MM-DD
    }

    formatTime(dateTimeStr) {
        if (!dateTimeStr) return '';
        const dt = new Date(dateTimeStr);
        return dt.toTimeString().split(' ')[0]; // returns HH:mm:ss
    }

}