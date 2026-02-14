import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues as getOppPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

// Apex Methods
import searchRetailUnits from '@salesforce/apex/RETL_UnitSearch.searchRetailUnits';
import createProductsForUnits from '@salesforce/apex/RETL_UnitSearch.createProductsForUnits';
import getPicklistValues from '@salesforce/apex/RETL_UnitSearch.getPicklistValues';
import getOpportunitiesForUnits from '@salesforce/apex/RETL_UnitSearch.getOpportunitiesForUnits';
import getAllProperties from '@salesforce/apex/RETL_UnitSearch.getAllProperties';
import refreshUnitAvailability from '@salesforce/apex/RETL_UnitSearch.refreshUnitAvailability';
import getLineItemCount from '@salesforce/apex/RETL_UnitSearch.getLineItemCount';
import getLineItems from '@salesforce/apex/RETL_UnitSearch.getLineItems';
import updateProposal from '@salesforce/apex/RETL_UnitSearch.updateProposal';


// Schema Imports - Opportunity Object
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import HANDOVER_CONDITIONS_FIELD from '@salesforce/schema/Opportunity.RETL_Handover_Conditions__c';
import FITOUT_DAYS_FIELD from '@salesforce/schema/Opportunity.RETL_Fitout_Days__c';
import DESIRED_RENT_FIELD from '@salesforce/schema/Opportunity.RETL_Desired_Rent__c';
import DESIRED_AREA_FIELD from '@salesforce/schema/Opportunity.RETL_Desired_Area__c';
import DEPOSIT_AMOUNT_FIELD from '@salesforce/schema/Opportunity.RETL_Deposit_Amount__c';
import TOR_FIELD from '@salesforce/schema/Opportunity.RETL_TOR__c';
import ESCALATION_FIELD from '@salesforce/schema/Opportunity.RETL_Escalation__c';
import START_DATE_FIELD from '@salesforce/schema/Opportunity.Start_date__c';
import PROJECT_FIELD from '@salesforce/schema/Opportunity.Project__c';
import PROPERTY_NAME_FIELD from '@salesforce/schema/Opportunity.RETL_Project__r.Name';
import TERM_START_DATE from '@salesforce/schema/Opportunity.RETL_Term_Start_Date__c';
import TERM_END_DATE from '@salesforce/schema/Opportunity.RETL_Term_End_Date__c';
import TERM from '@salesforce/schema/Opportunity.RETL_Term__c';
import MONTH_TO_MONTH from '@salesforce/schema/Opportunity.RETL_Month_Month__c';
import LEASE_NATURE from '@salesforce/schema/Opportunity.RETL_Lease_Nature__c';
import FITOUT_TYPE from '@salesforce/schema/Opportunity.RETL_Fitout_Type__c';
import TOTAL_BASE_RENT_FIELD from '@salesforce/schema/Opportunity.RETL_Total_Base_Rent__c';
import TOTAL_SERVICE_CHARGE_FIELD from '@salesforce/schema/Opportunity.RETL_Total_Service_Charge__c';
import TOTAL_MARKETING_FIELD from '@salesforce/schema/Opportunity.RETL_Total_Marketing_Amount__c';
import CONFIGURE_BY from '@salesforce/schema/Opportunity.RETL_Configure_By__c';
import BILLING_FREQENCY from '@salesforce/schema/Opportunity.RETL_Billing_Frequency__c';

import GENERAL_NOTES from '@salesforce/schema/Opportunity.RETL_General_Notes__c';
import DEPOSIT_NOTES from '@salesforce/schema/Opportunity.RETL_Deposit_Notes__c';
import SPECIAL_CONDITIONS from '@salesforce/schema/Opportunity.RETL_Special_Conditions__c';
import FOC_INFORMATION from '@salesforce/schema/Opportunity.RETL_FOC_Information__c';
import PERMITTED_USAGE from '@salesforce/schema/Opportunity.RETL_Permitted_Usage__c';
import TOR_NOTES from '@salesforce/schema/Opportunity.RETL_TOR_Notes__c';

import TOTAL_RENT_FREE from '@salesforce/schema/Opportunity.RETL_Total_Rent_Free_Amount__c';
import TOTAL_FOC_AMOUNT from '@salesforce/schema/Opportunity.RETL_Total_FOC_Amount__c';





export default class RetailUnitSearch extends LightningElement {
    // -----------------------------------------------------
    // 1. PUBLIC PROPERTIES (@api)
    // -----------------------------------------------------
    @api recordId; // Opportunity Id from record page

    // -----------------------------------------------------
    // 2. PRIVATE REACTIVE PROPERTIES (@track)
    // -----------------------------------------------------
    // Search/Table State
    @track building = '';
    @track property = '';
    @track units;
    @track selectedRows = [];
    @track selectedUnits = [];
    @track isLoading = false;
    @track minArea = 0;
    @track maxArea = 50000;
    @track pageSize = 10;

    // Filters (Passed to Apex)
    @track selectedStatuses = [];
    @track selectedTypes = [];

    // Filter Options
    fullUnitStatusOptions = [];
    fullUnitTypeOptions = [];
    fullHandoverConditionOptions = [];
    billingFrequencyOptions = [];

    // Custom Multi-Select State
    @track unselectedStatusOptions = [];
    @track unselectedTypeOptions = [];
    @track selectedStatusPills = [];
    @track selectedTypePills = [];

    // Sorting State
    @track sortedBy = 'UnitID_External_ID__c'; // Default sort field
    @track sortedDirection = 'asc'; // Default sort direction

    // Refresh Modal State
    @track showRefreshModal = false;
    @track propertyOptions = [];
    @track selectedProperty = '';
    @track isModalLoading = false;
    @track selectedRefreshType = 'byProperty';

    // Configuration View State
    @api  showConfiguration = false; // Controls the view (Search/Table vs. Configuration)
    @api  editMode = false;
    @track configureBy = 'Unit Level';

    // Opportunity Fields State
    @track lineItemCount = 0;
    @track desiredArea;
    @track desiredRent;
    @track depositAmount;
    @track torPercentage;
    @track escalationPercentage;
    @track startDate;
    @track selectedHandoverCondition = '';
    @track leaseNature;
    @track billingFrequency = '';
    @track termStartDate;
    @track termEndDate;
    @track minTermEndDate; // Minimum allowed end date
    @track fitoutType;
    @track monthToMonth = false;
    @track depositNotes = '';
    @track torNotes = '';
    @track specialConditions = '';
    @track focInformation = '';
    @track term;
    @track closeDate;
    @track fitoutDays;
    @track generalNotes;
    @track permittedUsage;

    // Total Calculation State
    @track totalBaseRent = 0;
    @track totalServiceCharge = 0;
    @track totalMarketingAmount = 0;
    @track totalBaseRentWords;
    @track totalServiceChargeWords;
    @track totalMarketingAmountWords;
    totalBaseRentNumeric = 0;
    totalServiceChargeNumeric = 0;
    totalMarketingAmountNumeric = 0;
    @track totalRentFreeAmount = 0;
    @track totalFitoutContAmount = 0;
    totalRentFreeAmountNumeric = 0;
    totalFitoutContAmountNumeric = 0;

    @track totalBaseRentBudgeted = 0; // this value wont change
    @track totalServiceChargeBudgeted = 0; // this value wont change
    @track totalRentFreeBudgeted = 0; // this value wont change
    @track totalFOCBudgeted = 0; // this value wont change
    @track totalMarketingAmountBudgeted = 0; // this value wont change

    // Pre-Approval/Variance State
    @track budgetVariance = false;
    @track natureVariance = false;
    @track redemiseChange = false;
    @track showApprovalRequired = false;
    @track isAdditionalInfoOpen = false;
    @track approvalSummaryText = '';

    // -----------------------------------------------------
    // 3. WIRED PROPERTIES AND FUNCTIONS
    // -----------------------------------------------------

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [
            FITOUT_DAYS_FIELD,
            DESIRED_RENT_FIELD,
            DEPOSIT_AMOUNT_FIELD,
            TOR_FIELD,
            START_DATE_FIELD,
            DESIRED_AREA_FIELD,
            HANDOVER_CONDITIONS_FIELD,
            PROJECT_FIELD,
            TERM_START_DATE,
            TERM_END_DATE,
            TERM,
            MONTH_TO_MONTH,
            LEASE_NATURE,
            FITOUT_TYPE,
            ESCALATION_FIELD,
            BILLING_FREQENCY,
            TOTAL_BASE_RENT_FIELD,
            TOTAL_SERVICE_CHARGE_FIELD,
            TOTAL_MARKETING_FIELD,
            PROPERTY_NAME_FIELD,
            CONFIGURE_BY,
            GENERAL_NOTES,
            DEPOSIT_NOTES,
            SPECIAL_CONDITIONS,
            FOC_INFORMATION,
            PERMITTED_USAGE,
            TOR_NOTES,            
            TOTAL_FOC_AMOUNT,
            TOTAL_RENT_FREE
        ]
    })
    wiredOpportunity({ error, data }) {
        if (data) {

            // build opportunity snapshot
            let snapshot = {
                Id: data.id,
                RETL_Handover_Conditions__c: data.fields.RETL_Handover_Conditions__c?.value,
                RETL_Fitout_Days__c: data.fields.RETL_Fitout_Days__c?.value,
                RETL_Desired_Rent__c: data.fields.RETL_Desired_Rent__c?.value,
                RETL_Desired_Area__c: data.fields.RETL_Desired_Area__c?.value,
                RETL_Deposit_Amount__c: data.fields.RETL_Deposit_Amount__c?.value,
                RETL_TOR__c: data.fields.RETL_TOR__c?.value,
                RETL_Escalation__c: data.fields.RETL_Escalation__c?.value,
                Start_date__c: data.fields.Start_date__c?.value,                
                RETL_Term_Start_Date__c: data.fields.RETL_Term_Start_Date__c?.value,
                RETL_Term_End_Date__c: data.fields.RETL_Term_End_Date__c?.value,
                RETL_Term__c: data.fields.RETL_Term__c?.value,
                RETL_Month_Month__c: data.fields.RETL_Month_Month__c?.value,
                RETL_Lease_Nature__c: data.fields.RETL_Lease_Nature__c?.value,
                RETL_Fitout_Type__c: data.fields.RETL_Fitout_Type__c?.value,
                RETL_Billing_Frequency__c: data.fields.RETL_Billing_Frequency__c?.value,
                RETL_Configure_By__c: data.fields.RETL_Configure_By__c?.value,
                RETL_General_Notes__c: data.fields.RETL_General_Notes__c?.value,
                RETL_Deposit_Notes__c: data.fields.RETL_Deposit_Notes__c?.value,
                RETL_TOR_Notes__c: data.fields.RETL_TOR_Notes__c?.value,
                RETL_Special_Conditions__c: data.fields.RETL_Special_Conditions__c?.value,
                RETL_FOC_Information__c: data.fields.RETL_FOC_Information__c?.value,
                RETL_Permitted_Usage__c: data.fields.RETL_Permitted_Usage__c?.value,
                RETL_AM_PreApproval__c: data.fields.RETL_AM_PreApproval__c?.value,
                RETL_AM_PreApproval_Notes__c: data.fields.RETL_AM_PreApproval_Notes__c?.value
            };


            // store original snapshot only once
            if (!this.originalOppValuesLoaded) {
                this.originalOppValues = JSON.parse(JSON.stringify(snapshot));
                this.originalOppValuesLoaded = true;
            }




            this.fitoutDays = data.fields.RETL_Fitout_Days__c?.value;
            this.desiredRent = data.fields.RETL_Desired_Rent__c?.value;
            this.desiredArea = data.fields.RETL_Desired_Area__c?.value;
            this.depositAmount = data.fields.RETL_Deposit_Amount__c?.value;
            this.selectedHandoverCondition = data.fields.RETL_Handover_Conditions__c?.value;
            this.torPercentage = data.fields.RETL_TOR__c?.value;
            this.escalationPercentage = data.fields.RETL_Escalation__c?.value;
            this.startDate = data.fields.Start_date__c?.value;
            this.selectedProperty = data.fields.Project__c?.value;
            //this.property = data.fields.Project__c?.value;
            this.property = data.fields.Project__c?.value || data.fields.RETL_Property__r?.value?.fields?.Name?.value;
            this.termStartDate = data.fields.RETL_Term_Start_Date__c?.value;
            this.termEndDate = data.fields.RETL_Term_End_Date__c?.value;
            this.term = data.fields.RETL_Term__c?.value;
            this.monthToMonth = data.fields.RETL_Month_Month__c?.value;
            this.leaseNature = data.fields.RETL_Lease_Nature__c?.value;
            this.fitoutType = data.fields.RETL_Fitout_Type__c?.value;
            this.billingFrequency = data.fields.RETL_Billing_Frequency__c?.value;
            this.configureBy = data.fields.RETL_Configure_By__c?.value != null ? data.fields.RETL_Configure_By__c.value : 'Unit Level';



            this.totalBaseRent = data.fields.RETL_Total_Base_Rent__c?.value;
            this.totalMarketingAmount = data.fields.RETL_Total_Marketing_Amount__c?.value;
            this.totalServiceCharge = data.fields.RETL_Total_Service_Charge__c?.value;
            this.totalRentFreeAmount = data.fields.RETL_Total_Rent_Free_Amount__c?.value;
            this.totalFitoutContAmount = data.fields.RETL_Total_FOC_Amount__c?.value;

            
            this.depositNotes = data.fields.RETL_Deposit_Notes__c?.value;
            this.specialConditions = data.fields.RETL_Special_Conditions__c?.value;
            this.focInformation = data.fields.RETL_FOC_Information__c?.value;
            this.permittedUsage = data.fields.RETL_Permitted_Usage__c?.value;
            this.torNotes = data.fields.RETL_TOR_Notes__c?.value;
            this.generalNotes = data.fields.RETL_General_Notes__c?.value;

            this.searchUnits(); // Search after Property is set
        } else if (error) {
            console.error('Error loading opportunity fields:', error);
        }
    }

    @wire(getLineItemCount, { opportunityId: '$recordId' })
    wiredLineItems({ data, error }) {
        if (data !== undefined) {
            this.lineItemCount = data;
            this.pageSize = this.lineItemCount > 0 ? 500 : 10;    
            this.searchUnits();        
            console.log('Line Item Count:', this.lineItemCount);
        } else if (error) {
            console.error(error);
        }
    }

    // -----------------------------------------------------
    // 4. LIFECYCLE HOOKS
    // -----------------------------------------------------

    connectedCallback() {
        this.searchUnits();
        this.loadPicklists();
        this.loadPropertyOptions();
        if (this.editMode) {
            this.loadExistingLineItems();                   
        }
    }

    // -----------------------------------------------------
    // 5. GETTERS (Computed Properties)
    // -----------------------------------------------------
    get refreshTypeOptions() {
        return [
            { label: 'Refresh by Property', value: 'byProperty' },
            { label: 'Refresh Full Availability', value: 'full' }
        ];
    }
    
    get pageSizeOptions() {
    return [
        { label: '10', value: '10' },
        { label: '50', value: '50' },
        { label: '100', value: '100' },
        { label: '500', value: '500' },
        { label: '2000', value: '2000' },
        { label: 'All', value: 'All' } // use string 'All'
    ];
}
    
    get isPropertyRefresh() {
        return this.selectedRefreshType === 'byProperty';
    }

    get isFullRefresh() {
        return this.selectedRefreshType === 'full';
    }

    get disableRefresh() {
        if (this.isModalLoading) return true;
        if (this.isPropertyRefresh) return !this.selectedProperty;
        return false; // full refresh has no dependency
    }

    get cartCount() {
        return this.selectedRows ? this.selectedRows.length : 0;
    }

    get disableConfigureButton() {
        return this.cartCount === 0;
    }

    get fitoutTypeOptions() {
        return [
            { label: 'Before', value: 'Before' },
            { label: 'After', value: 'After' }
        ];
    }
    
    get leaseNatureOptions() {
        return [
            { label: 'Retail', value: 'Retail' },
            { label: 'FnB', value: 'FnB' },
            { label: 'Others', value: 'Others' }
        ];
    }

    get configureByOptions() {
        return [
            { label: 'Deal Level', value: 'Deal Level' },
            { label: 'Unit Level', value: 'Unit Level' }
        ];
    }

    get isDealLevel() {
        return this.configureBy === 'Deal Level';
    }

    get isUnitLevel() {
        return this.configureBy === 'Unit Level';
    }

    get isNotDealLevel() {
        return this.configureBy !== 'Deal Level';
    }
    
    get showUnitLevelFields() {
        return this.configureBy !== 'Deal Level';
    }

    get additionalInfoSectionClass() {
        return `slds-section ${this.isAdditionalInfoOpen ? 'slds-is-open' : ''}`;
    }

    get additionalInfoIcon() {
        return this.isAdditionalInfoOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get hideCheckbox() {
        return this.lineItemCount > 0;
    }

    get pageSizeLabel() {
        // return the label for current numeric pageSize
        if (this.pageSize === 50000) return 'All';
        return this.pageSize?.toString();
    }

    // -----------------------------------------------------
    // 6. DATATABLE CONFIGURATION
    // -----------------------------------------------------

    columns = [
        { label: 'Yardi Id', fieldName: 'UnitID_External_ID__c', sortable: true },
        { label: 'Unit Code', fieldName: 'Unit_Code__c', sortable: true },
        { label: 'Unit Area', fieldName: 'Unit_Area__c', type: 'number', sortable: true },
        { label: 'Floor', fieldName: 'Floor__c', sortable: true }, 
        { label: 'Unit Type', fieldName: 'Unit_Type__c', sortable: true },
        { label: 'Unit Nature', fieldName: 'Unit_Nature__c', sortable: true },
        { label: 'Unit Status', fieldName: 'Unit_Status__c', sortable: true },        
        { label: 'Expiry Date', fieldName: 'Expiry_Date__c', type: 'date', sortable: true },
        { label: 'Expires In Days', fieldName: 'Expires_In_Days__c', type: 'number', sortable: true },        
        { label: 'Tenant Name', fieldName: 'Tenant_Name__c', sortable: true },     
        { label: 'Amount Type', fieldName: 'Amount_Type__c', sortable: true },
        { label: 'Net Marketing Budget', fieldName: 'Net_Marketing_Budget__c', type: 'currency', sortable: true },
        { label: 'Net Service Charge Budget', fieldName: 'Net_Service_Charge_Budget__c', type: 'currency', sortable: true },
        { label: 'Fitout Contribution Amount', fieldName: 'Fitout_Contribution_Amount__c', type: 'currency', sortable: true },
        { label: 'Rent Budget', fieldName: 'Rent_Budget__c', type: 'currency', sortable: true },
        { label: 'Rent Free Amount', fieldName: 'Rent_Free_Amount__c', type: 'currency', sortable: true },
        // The commented out column is here for completeness as it was in the source
        // { label: 'Status', fieldName: 'alreadyAddedLabel', type: 'text', cellAttributes: { class: { fieldName: 'alreadyAddedLabelClass' } } }
    ];

    // -----------------------------------------------------
    // 7. CORE LOGIC METHODS (Search, Picklist, Property Load)
    // -----------------------------------------------------

    loadPicklists() {
        // Load Unit__c picklists
        getPicklistValues({ 
            objectApiName: 'Retail_Unit__c', 
            fieldApiNames: ['Unit_Status__c', 'Unit_Type__c'] 
        })
        .then(data => {
            if (data.Unit_Status__c) {
                this.fullUnitStatusOptions = data.Unit_Status__c.map(val => ({ label: val, value: val }));
                this.unselectedStatusOptions = [...this.fullUnitStatusOptions];
            }
            if (data.Unit_Type__c) {
                this.fullUnitTypeOptions = data.Unit_Type__c.map(val => ({ label: val, value: val }));
                this.unselectedTypeOptions = [...this.fullUnitTypeOptions];
            }
        })
        .catch(error => {
            console.error('Error loading Unit__c picklists:', error);
        });

        // Load Opportunity picklists
        getPicklistValues({ 
            objectApiName: 'Opportunity', 
            fieldApiNames: ['RETL_Billing_Frequency__c', 'RETL_Handover_Conditions__c'] 
        })
        .then(data => {
            if (data.RETL_Billing_Frequency__c) {
                this.billingFrequencyOptions = data.RETL_Billing_Frequency__c.map(val => ({ label: val, value: val }));
            }
            if (data.RETL_Handover_Conditions__c) {
                this.fullHandoverConditionOptions = data.RETL_Handover_Conditions__c.map(val => ({ label: val, value: val }));
            }
        })
        .catch(error => {
            console.error('Error loading Opportunity picklists:', error);
        });
    }

    loadPropertyOptions() {
        getAllProperties()
            .then(result => {
                this.propertyOptions = result.map(p => ({ label: p, value: p }));                
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to load properties', 'error');
            });
    }

    searchUnits() {
        this.isLoading = true;
        searchRetailUnits({ 
            building: this.building,
            property: this.property,
            statuses: this.selectedStatuses, // Uses the custom multi-select array
            types: this.selectedTypes,       // Uses the custom multi-select array
            pageSize: this.pageSize,
            offsetValue: this.offsetValue,
            minArea: this.minArea,
            maxArea: this.maxArea,
            currentOpportunityId: this.recordId
        })
        .then(result => {
            let processedUnits = result.map(r => {
                // ensure boolean and label shapes are correct
                return {
                    ...r,
                    alreadyAdded: r.alreadyAdded === true || r.alreadyAdded === 'true',
                    alreadyAddedLabel: r.alreadyAdded ? 'Already added' : '',
                    alreadyAddedLabelClass: r.alreadyAdded ? 'already-added-cell' : ''
                };
            });
            
            // Apply sorting after fetching
            if (this.sortedBy && this.sortedDirection) {
                this.sortData(this.sortedBy, this.sortedDirection, processedUnits);                
            } else {
                this.units = processedUnits;
            }
        })
        .catch(error => {
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast('Error', message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    // -----------------------------------------------------
    // 8. HANDLERS (Filtering & Configuration)
    // -----------------------------------------------------

    // General Filters
    clearFilters() {
        this.property = '';
        this.building = '';
        this.selectedStatuses = [];
        this.selectedTypes = [];
        this.selectedStatusPills = [];
        this.selectedTypePills = [];
        this.unselectedStatusOptions = [...this.fullUnitStatusOptions];
        this.unselectedTypeOptions = [...this.fullUnitTypeOptions];
        this.minArea = 0;
        this.maxArea = 50000;
        this.pageSize = 10;
        // Re-run the search with default values
        this.searchUnits();
    }

    handlePageSizeChange(event) {
        const val = event.detail.value;
        this.pageSize = val === 'All' ? 50000 : parseInt(val, 10);
        this.searchUnits();
    }


    handleMinAreaChange(event) {
        this.minArea = event.detail.value;
        this.searchUnits();
    }

    handleMaxAreaChange(event) {
        this.maxArea = event.detail.value;
        this.searchUnits();
    }

    handleBuildingChange(event) {
        this.building = event.target.value;
        this.searchUnits();
    }

    handlePropertyChange(event) {
        this.property = event.detail.value;
        this.searchUnits();
    }

    handleHandoverConditionsChange(event) {
        this.selectedHandoverConditionFilter = event.detail.value;
        this.selectedHandoverCondition = event.detail.value;
        this.searchUnits();
    }
    
    // Status Handlers (Custom Multi-Select)
    handleStatusSelection(event) {
        const selectedValue = event.detail.value;
        if (!selectedValue) return;

        const selectedOption = this.fullUnitStatusOptions.find(opt => opt.value === selectedValue);
        this.selectedStatusPills = [...this.selectedStatusPills, { label: selectedOption.label, name: selectedOption.value }];
        this.selectedStatuses = [...this.selectedStatuses, selectedOption.value];

        this.unselectedStatusOptions = this.unselectedStatusOptions.filter(opt => opt.value !== selectedValue);
        this.template.querySelector('.status-combobox').value = '';
        this.searchUnits();
    }

    handleStatusPillRemove(event) {
        const removedValue = event.detail.item.name;
        this.selectedStatusPills = this.selectedStatusPills.filter(pill => pill.name !== removedValue);
        this.selectedStatuses = this.selectedStatuses.filter(value => value !== removedValue);
        const addedOption = this.fullUnitStatusOptions.find(opt => opt.value === removedValue);
        this.unselectedStatusOptions = [...this.unselectedStatusOptions, addedOption]
            .sort((a, b) => a.label.localeCompare(b.label));
        this.searchUnits();
    }
    
    // Type Handlers (Custom Multi-Select)
    handleTypeSelection(event) {
        const selectedValue = event.detail.value;
        if (!selectedValue) return;

        const selectedOption = this.fullUnitTypeOptions.find(opt => opt.value === selectedValue);
        this.selectedTypePills = [...this.selectedTypePills, { label: selectedOption.label, name: selectedOption.value }];
        this.selectedTypes = [...this.selectedTypes, selectedOption.value];
        this.unselectedTypeOptions = this.unselectedTypeOptions.filter(opt => opt.value !== selectedValue);
        this.template.querySelector('.type-combobox').value = '';
        this.searchUnits();
    }

    handleTypePillRemove(event) {
        const removedValue = event.detail.item.name;
        this.selectedTypePills = this.selectedTypePills.filter(pill => pill.name !== removedValue);
        this.selectedTypes = this.selectedTypes.filter(value => value !== removedValue);
        const addedOption = this.fullUnitTypeOptions.find(opt => opt.value === removedValue);
        this.unselectedTypeOptions = [...this.unselectedTypeOptions, addedOption]
            .sort((a, b) => a.label.localeCompare(b.label));
        this.searchUnits();
    }

    // Datatable and Selection Handlers
    handleRowSelection(event) {
        const rawSelectedRows = event.detail.selectedRows;
        const filtered = rawSelectedRows.filter(r => !r.alreadyAdded);
        this.selectedRows = filtered.map(r => r.Id);
        if (rawSelectedRows.length !== filtered.length) {
            this.showToast('Warning', 'Some units were already added to this Opportunity and were not selected.', 'warning');
            // Reassigning this.selectedRows updates the datatable selection
        }
    }

    handleSort(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(fieldName, sortDirection, this.units);
    }

    // Configuration View Toggle
    configureUnits() {
        this.selectedUnits = this.units
            .filter(u => this.selectedRows.includes(u.Id))
            .map(u => ({
                ...u,
                price: 0,
                opportunities: [],
                originalBaseRent: u.Rent_Budget__c,   // store original rent
                hasBaseRentVariance: false,           // flag for variance
                rentVarianceValue: 0                  // numeric variance
            }));
        this.showConfiguration = true;
        this.fetchUnitOpportunities();
        this.recalculateTotals();
        this.checkNatureVariance();
        this.checkBudgetVariance();

    }

    closeConfiguration() {
        this.showConfiguration = false;
        // Optional: Re-select the rows in the table when returning, if you don't want to clear the 'cart'
        // this.selectedRows = this.selectedUnits.map(u => u.Id);
    }

    clearCart() {
        this.selectedRows = [];
        this.selectedUnits = [];
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.selectedRows = [];
        }
        this.showToast("Cart Cleared", "All units have been removed from the selection.", "info");
        this.closeConfiguration();
    }

    // Unit-Level Configuration Handlers
    handleUnitValueChange(event) {
        const unitId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = parseFloat(event.target.value) || 0;
        this.selectedUnits = this.selectedUnits.map(unit => {
            if (unit.Id === unitId) {
                unit[field] = value;

                if (field === 'Rent_Budget__c') {
                    const original = parseFloat(unit.originalBaseRent) || 0;
                    unit.hasBaseRentVariance = value !== original;
                    unit.rentVarianceValue = value - original;
                }
            }
            return unit;
        });
        this.recalculateTotals();
        this.checkBudgetVariance();

    }
    
    // Deal-Level Configuration Handlers
    /* handleConfigureByChange(event) {
        this.configureBy = event.detail.value;
        console.log('Configure by:', this.configureBy);
        if (this.configureBy === 'Deal Level') {
            this.selectedUnits = this.selectedUnits.map(unit => ({
                ...unit,
                Rent_Budget__c: null,
                Net_Service_Charge_Budget__c: null,
                Net_Marketing_Budget__c: null
            }));
        } else if (this.configureBy === 'Unit Level') {
            this.totalBaseRent = '';
            this.totalServiceCharge = '';
            this.totalMarketingAmount = '';
        }
        this.recalculateTotals();
        this.checkBudgetVariance();

    } */
    _unitLevelCache = [];
    handleConfigureByChange(event) {        
        const newConfigureBy = event.detail.value;
        const previousConfigureBy = this.configureBy; 
        this.configureBy = newConfigureBy;
        console.log('Configure by:', this.configureBy);
        if (this.configureBy === 'Deal Level') {
            if (previousConfigureBy === 'Unit Level') {
                // Take a deep clone of the current unit data (which holds the values we need to save)
                this._unitLevelCache = JSON.parse(JSON.stringify(this.selectedUnits));
            }
            this.selectedUnits = this.selectedUnits.map(unit => ({
                ...unit,
                Rent_Budget__c: null,
                Net_Service_Charge_Budget__c: null,
                Net_Marketing_Budget__c: null,
                Rent_Free_Amount__c: null,
                Fitout_Contribution_Amount__c: null
            }));

        } else if (this.configureBy === 'Unit Level') {  
            if (this._unitLevelCache && this._unitLevelCache.length > 0) {
                this.selectedUnits = this.selectedUnits.map(unit => {
                    const cachedUnit = this._unitLevelCache.find(cUnit => cUnit.Id === unit.Id);
                    
                    if (cachedUnit) {
                        return {
                            ...unit,
                            Rent_Budget__c: cachedUnit.Rent_Budget__c,
                            Net_Service_Charge_Budget__c: cachedUnit.Net_Service_Charge_Budget__c,
                            Net_Marketing_Budget__c: cachedUnit.Net_Marketing_Budget__c,
                            Rent_Free_Amount__c: cachedUnit.Rent_Free_Amount__c,
                            Fitout_Contribution_Amount__c: cachedUnit.Fitout_Contribution_Amount__c
                        };
                    }
                    return unit;
                });
            }
            // Clear Deal Level Totals
            this.totalBaseRent = '';
            this.totalServiceCharge = '';
            this.totalMarketingAmount = '';
        }

        this.recalculateTotals();
        this.checkBudgetVariance();
    }

    handleTotalBaseRentChange(event) {
        this.totalBaseRentNumeric = parseFloat(event.target.value) || 0;
        this.totalBaseRent = event.target.value;
        this.recalculateTotals();
        this.checkBudgetVariance();

    }

    handleTotalServiceChargeChange(event) {
        this.totalServiceChargeNumeric = parseFloat(event.target.value) || 0;
        this.totalServiceCharge = event.target.value;
        this.recalculateTotals();
        this.checkBudgetVariance();

    }

    handleTotalMarketingAmountChange(event) {
        this.totalMarketingAmountNumeric = parseFloat(event.target.value) || 0;
        this.totalMarketingAmount = event.target.value;
        this.recalculateTotals();
        this.checkBudgetVariance();

    }

    handleTotalRentFreeAmountChange(event) {
        this.totalRentFreeAmountNumeric = parseFloat(event.target.value) || 0;
        this.totalRentFreeAmount = event.target.value;
        this.recalculateTotals();
        this.checkBudgetVariance();
    }

    handleTotalFitoutContAmtChange(event) {
        this.totalFitoutContAmountNumeric = parseFloat(event.target.value) || 0;
        this.totalFitoutContAmount = event.target.value;
        this.recalculateTotals();
        this.checkBudgetVariance();
    }


    // Opportunity Field Handlers
    handleCloseDateChange(event) {
        this.closeDate = event.target.value;
    }

    handleFitoutDaysChange(event) {
        this.fitoutDays = event.target.value;
    }

    handleHandoverConditionChange(event) {
        this.selectedHandoverCondition = event.detail.value;
    }

    handleDesiredAreaChange(event) {
        this.desiredArea = event.target.value;
    }

    handleDesiredRentChange(event) {
        this.desiredRent = event.target.value;
    }

    handleDepositAmountChange(event) {
        this.depositAmount = event.target.value;
    }

    handleDepositNotesChange(event) {
        this.depositNotes = event.target.value;
    }

    handleTorChange(event) {
        this.torPercentage = event.target.value;
    }

    handleEscalationPercentageChange(event) {
        this.escalationPercentage = event.target.value;
    }

    handleTorNotesChange(event) {
        this.torNotes = event.target.value;
    }

    handleSpecialConditionsChange(event) {
        this.specialConditions = event.target.value;
    }

    handleFocInformationChange(event) {
        this.focInformation = event.target.value;
    }

    handlestartDateChange(event) {
        this.startDate = event.target.value;
    }

    /* handleTermStartDateChange(event) {
        this.termStartDate = event.target.value;
    }
    
    handleTermEndDateChange(event) {
        this.termEndDate = event.target.value;
    } */

    handleTermStartDateChange(event) {
        this.termStartDate = event.target.value;

        if (this.termStartDate) {
            const startDate = new Date(this.termStartDate);
            const minEndDate = new Date(startDate);
            minEndDate.setFullYear(minEndDate.getFullYear() + 1); // Add 1 year
            this.minTermEndDate = minEndDate.toISOString().split('T')[0];

            // Optional: reset end date if it's before new min
            if (this.termEndDate && new Date(this.termEndDate) < minEndDate) {
                this.termEndDate = null;
            }
        } else {
            this.minTermEndDate = null;
        }
    }

    handleTermEndDateChange(event) {
        this.termEndDate = event.target.value;

        if (this.termStartDate) {
            const startDate = new Date(this.termStartDate);
            const minEndDate = new Date(startDate);
            minEndDate.setFullYear(minEndDate.getFullYear() + 1);

            const selectedEndDate = new Date(this.termEndDate);
            if (selectedEndDate < minEndDate) {
                event.target.setCustomValidity('Term End Date must be at least 1 year after Term Start Date.');
            } else {
                event.target.setCustomValidity('');
            }

            event.target.reportValidity();
        }
    }

    handleFitoutTypeChange(event) {
        this.fitoutType = event.target.value;
    }

    handleMonthToMonthChange(event) {
        this.monthToMonth = event.target.checked;
    }

    handleGeneralNotesChange(event) {
        this.generalNotes = event.target.value;
    }

    handleTermChange (event) {
        this.term = event.target.value;
    }
    
    handleLeaseNatureChange(event) {
        this.leaseNature = event.target.value;
        this.checkNatureVariance();
    }


    handleBillingFrequencyChange(event) {
        this.billingFrequency = event.detail.value;
    }

    handleApprovalSummaryChange(event) {
        this.approvalSummaryText = event.target.value;
    }

    handlePermittedUsageChange(event) {
        this.permittedUsage = event.target.value;
    }
    
    toggleAdditionalInfo() {
        this.isAdditionalInfoOpen = !this.isAdditionalInfoOpen;
    }

    // -----------------------------------------------------
    // 9. REFRESH MODAL HANDLERS
    // -----------------------------------------------------

    async handlePropertyRefresh() {
        if (!this.property) {
            this.showToast('Error', 'Please select a property to refresh its availability.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            await refreshUnitAvailability({ propertyName: this.property, fullRefresh: false });
            this.showToast('Success', `Unit availability refresh for ${this.property} successfully fetched.`, 'success');
            this.searchUnits();
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to queue property refresh.', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    openRefreshModal() {
        this.showRefreshModal = true;
        this.loadPropertyOptions();
    }

    closeRefreshModal() {
        this.showRefreshModal = false;
        this.selectedProperty = '';
    }

    handlePropertySelection(event) {
        this.selectedProperty = event.detail.value;
    }
    
    handleRefreshTypeChange(event) {
        this.selectedRefreshType = event.detail.value;
        if (this.isFullRefresh) {
            this.selectedProperty = '';
        }
    }

    handleRefreshAvailability() {
        this.isModalLoading = true;
        if (this.isPropertyRefresh && !this.selectedProperty) {
            this.showToast('Error', 'Please select a property', 'error');
            this.isModalLoading = false;
            return;
        }

        const isFull = this.isFullRefresh;
        const prop = this.isPropertyRefresh ? this.selectedProperty : null; 

        refreshUnitAvailability({ propertyName: prop, fullRefresh: isFull })
            .then(() => {
                if (isFull) {
                    this.showToast('Success', 'Full refresh started. Please come visit the page after sometime.', 'success');
                } else {
                    this.showToast('Success', 'Unit availability refresh successfully queued. Refreshing list...', 'success');
                    this.searchUnits();
                }
                this.closeRefreshModal();
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to refresh units', 'error');
            })
            .finally(() => {
                this.isModalLoading = false;
            });
    }

    // -----------------------------------------------------
    // 10. GENERATE PROPOSAL & SUPPORT METHODS
    // -----------------------------------------------------
    
    async generateProposal() {
        // Validate required fields first
        if (!this.validateFields()) {
            this.showToast('Error', 'Please fill all required fields before saving.', 'error');
            return;   // STOP — do not call Apex
        }

        if (!this.recordId) return;

        // Map selected units to unitWrappers
        const unitWrappers = (this.selectedUnits || []).map(u => ({
            unitId: u.Id,
            price: u.Rent_Budget__c || 0,
            marketingAmount: u.Net_Marketing_Budget__c,
            serviceCharge: u.Net_Service_Charge_Budget__c,
            rentFreeAmount: u.Rent_Free_Amount__c,
            fitoutContributionAmount: u.Fitout_Contribution_Amount__c,
            quantity: 1 // Always 1 as Unit is Unique
        }));

        console.log('unitWrappers:', unitWrappers);

        this.isLoading = true;

        try {
            // Build opportunity fields dynamically
            const opportunityFields = { Id: this.recordId };

            function addIfValue(fieldName, value) {
                if (value !== null && value !== undefined && value !== '') {
                    opportunityFields[fieldName] = value;
                }
            }

            // Add all fields only if they have a value
            addIfValue('RETL_Handover_Conditions__c', this.selectedHandoverCondition);
            addIfValue('RETL_Fitout_Days__c', this.fitoutDays);
            addIfValue('RETL_Desired_Rent__c', this.desiredRent);
            addIfValue('RETL_Desired_Area__c', this.desiredArea);
            addIfValue('RETL_Deposit_Amount__c', this.depositAmount);
            addIfValue('RETL_TOR__c', this.torPercentage);
            addIfValue('RETL_Escalation__c', this.escalationPercentage);
            addIfValue('Start_date__c', this.startDate);
            addIfValue('CloseDate', this.startDate);
            addIfValue('RETL_Term_Start_Date__c', this.termStartDate);
            addIfValue('RETL_Term_End_Date__c', this.termEndDate);
            addIfValue('RETL_Fitout_Type__c', this.fitoutType);
            addIfValue('RETL_Month_Month__c', this.monthToMonth);
            addIfValue('RETL_Deposit_Notes__c', this.depositNotes);
            addIfValue('RETL_TOR_Notes__c', this.torNotes);
            addIfValue('RETL_Special_Conditions__c', this.specialConditions);
            addIfValue('RETL_FOC_Information__c', this.focInformation);
            addIfValue('RETL_Term__c', this.term);
            addIfValue('RETL_General_Notes__c', this.generalNotes);
            addIfValue('RETL_Lease_Nature__c', this.leaseNature);
            addIfValue('RETL_Total_Base_Rent__c', this.totalBaseRentNumeric);
            addIfValue('RETL_Total_Service_Charge__c', this.totalServiceChargeNumeric);
            addIfValue('RETL_Total_Marketing_Amount__c', this.totalMarketingAmountNumeric);
            addIfValue('RETL_Total_FOC_Amount__c', this.totalFitoutContAmountNumeric);
            addIfValue('RETL_Total_Rent_Free_Amount__c', this.totalRentFreeAmountNumeric);
            addIfValue('RETL_Billing_Frequency__c', this.billingFrequency);
            addIfValue('RETL_Configure_By__c', this.configureBy);
            addIfValue('RETL_Permitted_Usage__c', this.permittedUsage);
            addIfValue('RETL_AM_PreApproval_Notes__c', this.approvalSummaryText);

            // Always set approval status
            opportunityFields.RETL_AM_PreApproval__c = this.showApprovalRequired ? 'Pending Approval' : 'Not Required';

            // Call Apex to create products / update opportunity
            const productIds = await createProductsForUnits({
                unitWrappers: unitWrappers,
                opportunityFields: opportunityFields,
                opportunityId: this.recordId
            });

            // Refresh record data
            if (this.recordId) {
                await getRecordNotifyChange([{ recordId: this.recordId }]);
                console.log('Opportunity record details refreshed.');
            }

            this.showToast('Success', `Proposal generated with ${productIds.length} products`, 'success');

            // Reload page if needed
            if (this.recordId) {
                window.location.reload(); 
            }

            // Clear selection and hide configuration modal
            this.showConfiguration = false;
            this.selectedUnits = [];
            this.selectedRows = [];
            this.searchUnits();

        } catch (error) {
            console.error('Error generating proposal', error);
            this.showToast('Error', error.body?.message || 'Error generating proposal', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Hold the Yardi Field Labels 
    // Map Salesforce API names to Yardi wrapper field codes
    yardiFieldMap = {
        RETL_Handover_Conditions__c: 'HANDOVER_CONDITION',
        RETL_Fitout_Days__c: 'FITOUT_DAYS',
        RETL_Desired_Rent__c: 'DESIRED_RENT',
        RETL_Desired_Area__c: 'DESIRED_AREA',
        RETL_Deposit_Amount__c: 'DEPOSIT',
        RETL_TOR__c: 'TOR',
        RETL_Escalation__c: 'ESCALATION',
        Start_date__c: 'DTLEASESTART',        
        RETL_Term_Start_Date__c: 'DTLEASESTART',
        RETL_Term_End_Date__c: 'DTLEASEEND',
        RETL_Fitout_Type__c: 'FITOUT_TYPE',
        RETL_Month_Month__c: 'MONTH_TO_MONTH',
        RETL_Deposit_Notes__c: 'DEPOSIT_NOTES',
        RETL_TOR_Notes__c: 'TOR_NOTES',
        RETL_Special_Conditions__c: 'SPECIAL_CONDITION',
        RETL_FOC_Information__c: 'FOC_INFORMATION',
        RETL_Term__c: 'TERM',
        RETL_General_Notes__c: 'GENERAL_NOTES',
        RETL_Lease_Nature__c: 'LEASE_NATURE',
        RETL_Billing_Frequency__c: 'BILLING_FREQUENCY',
        RETL_AM_PreApproval__c: 'AM_PREAPPROV',
        RETL_Configure_By__c: 'CONFIGURED_BY',
        RETL_Permitted_Usage__c: 'PERMITTED_USAGE',
        RETL_AM_PreApproval_Notes__c: 'PRE_APPROVAL_NOTES'
    };


    ignoredFields = ['Id', 'CloseDate']; // Add more if needed


    getChangedOppFieldLabels(newValues) {
        const changedYardiFields = [];

        for (let field in newValues) {
            // Skip ignored fields
            if (this.ignoredFields.includes(field)) continue;

            const oldVal = this.originalOppValues[field] ?? '';
            const newVal = newValues[field] ?? '';

            if (oldVal.toString() !== newVal.toString()) {
                const yardiKey = this.yardiFieldMap[field] || field;
                changedYardiFields.push(yardiKey);
            }
        }

        return changedYardiFields;
    }


    async updateEditedProposal() {
        if (!this.validateFields()) {
            this.showToast('Error', 'Please fill all required fields before saving.', 'error');
            return;
        }

        this.isLoading = true;

        try {
            // 1️ **Prepare Opportunity fields**
            const opportunityFields = {
                Id: this.recordId,
                RETL_Handover_Conditions__c: this.selectedHandoverCondition || null,
                RETL_Fitout_Days__c: this.fitoutDays || null,
                RETL_Desired_Rent__c: this.desiredRent || null,
                RETL_Desired_Area__c: this.desiredArea || null,
                RETL_Deposit_Amount__c: this.depositAmount || null,
                RETL_TOR__c: this.torPercentage || null,
                RETL_Escalation__c: this.escalationPercentage || null,
                Start_date__c: this.startDate || null,
                CloseDate: this.startDate || null,
                RETL_Term_Start_Date__c: this.termStartDate || null,
                RETL_Term_End_Date__c: this.termEndDate || null,
                RETL_Fitout_Type__c: this.fitoutType || null,
                RETL_Month_Month__c: this.monthToMonth || false,
                RETL_Deposit_Notes__c: this.depositNotes || '',
                RETL_TOR_Notes__c: this.torNotes || '',
                RETL_Special_Conditions__c: this.specialConditions || '',
                RETL_FOC_Information__c: this.focInformation || '',
                RETL_Term__c: this.term || null,
                RETL_General_Notes__c: this.generalNotes || '',
                RETL_Lease_Nature__c: this.leaseNature || null,
                RETL_Billing_Frequency__c: this.billingFrequency || null,
                RETL_AM_PreApproval__c: this.showApprovalRequired ? 'Pending Approval' : 'Not Required',
                RETL_Configure_By__c: this.configureBy || null,
                RETL_Permitted_Usage__c: this.permittedUsage || null,
                RETL_AM_PreApproval_Notes__c : this.approvalSummaryText || ''
            };

            const changedFields = this.getChangedOppFieldLabels(opportunityFields);
            opportunityFields.RETL_Work_Order_Notes__c = changedFields.join(', ');
            if(this.showApprovalRequired){
                opportunityFields.StageName = 'Pending AM Approval';
            }



            // 2️ **Prepare Line Item updates**
            const lineItemUpdates = this.selectedUnits.map(li => ({
                Id: li.Id,
                Quantity: li.Quantity,
                UnitPrice: li.Rent_Budget__c,
                RETL_Service_Charge__c: li.Net_Service_Charge_Budget__c,
                RETL_Marketing_Amount__c: li.Net_Marketing_Budget__c,
                RETL_Rent_Free_Amount__c: li.Rent_Free_Amount__c,
                RETL_Fitout_Contribution_Amount__c: li.Fitout_Contribution_Amount__c
            }));

            // 3️ Call Apex method to update OPP + OLI
            await updateProposal({
                opportunityFields: opportunityFields,
                lineItems: lineItemUpdates
            });

            await getRecordNotifyChange([{ recordId: this.recordId }]);

            this.showToast('Success', 'Proposal updated successfully.', 'success');
            window.location.reload();
            
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to update proposal', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    


    async fetchUnitOpportunities() {
        try {
            const yardiIds = this.selectedUnits.map(u => u.UnitID_External_ID__c);
            const result = await getOpportunitiesForUnits({ yardiIds });
            const baseUrl = window.location.origin;

            this.selectedUnits = this.selectedUnits.map(unit => {
                const opps = result[unit.UnitID_External_ID__c] || [];
                const oppsWithLinks = opps.map(o => ({
                    ...o,
                    link: `${baseUrl}/${o.Id}` // this adds full Salesforce record URL
                }));

                return {
                    ...unit,
                    opportunities: oppsWithLinks
                };
            });
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to fetch Opportunities', 'error');
        }
    }



    async loadExistingLineItems() {
        try {
            const lineItems = await getLineItems({ opportunityId: this.recordId });

            // Convert line items into the structure used by selectedUnits
            this.selectedUnits = lineItems.map(li => ({
                Id: li.Id,
                //Unit_Name_Formula__c: li.RETL_Selected_Unit__r.Unit_Name_Formula__c,
                Unit_Name_Formula__c:li.Name,
                Building__c: li.RETL_Selected_Unit__r.Building__c,
                Unit_Area__c: li.RETL_Selected_Unit__r?.Unit_Area__c || null,


                // Values used in your UI
                Rent_Budget__c: li.UnitPrice,                
                Fitout_Contribution_Amount__c: li.RETL_Fitout_Contribution_Amount__c,
                Actual_Service_Charge__c: li.Actual_Service_Charge__c,
                Net_Marketing_Budget__c: li.RETL_Marketing_Amount__c,
                Net_Service_Charge_Budget__c: li.RETL_Service_Charge__c,
                Rent_Free_Amount__c: li.RETL_Rent_Free_Amount__c,

                /* opportunities: [{
                    Id: li.OpportunityId,
                    Name: li.Opportunity.Name,
                    link: '/' + li.OpportunityId,
                    StageName: li.Opportunity.StageName,
                    //OwnerName: li.Opportunity.Owner.Name
                }], */
                
            }));

            // now show configuration
            this.showConfiguration = true;

            // recalc totals if needed
            //this.recalculateTotals();
            //this.checkNatureVariance();
            //this.checkBudgetVariance();
        } catch (error) {
            console.error('Error loading line items', error);
        }
    }

    originalOppValues = {};

    recalculateTotals() {
        let base = 0, service = 0, marketing = 0, rentFree = 0, fitout = 0; 
        this.totalBaseRentBudgeted = 0;        
        this.totalServiceChargeBudgeted = 0; 
        this.totalRentFreeBudgeted = 0; 
        this.totalFOCBudgeted = 0; 
        this.totalMarketingAmountBudgeted = 0;

        console.log('Selected Units:', this.selectedUnits);

        if (this.configureBy == 'Deal Level') {
            base = this.totalBaseRentNumeric || 0;
            service = this.totalServiceChargeNumeric || 0;
            marketing = this.totalMarketingAmountNumeric || 0;
            rentFree = this.totalRentFreeAmountNumeric || 0;
            fitout = this.totalFitoutContAmountNumeric || 0;
            console.log('Using deal-level totals:', base, service, marketing);
        } else {
            // Unit-level calculation
            this.selectedUnits.forEach(unit => {
                const rent = parseFloat(unit.Rent_Budget__c) || 0;
                const svc = parseFloat(unit.Net_Service_Charge_Budget__c) || 0;
                const mkt = parseFloat(unit.Net_Marketing_Budget__c) || 0;
                const rf  = parseFloat(unit.Rent_Free_Amount__c) || 0; 
                const fo  = parseFloat(unit.Fitout_Contribution_Amount__c) || 0; 

                const actualRent = parseFloat(unit.Actual_Rent__c) || 0;
                const actualSvc = parseFloat(unit.Actual_Service_Charge__c) || 0;
                const actualmktAmt = parseFloat(unit.Actual_Marketing_Budget__c) || 0;
                const actualrfAmt = parseFloat(unit.Actual_Rent_Free_Amount__c) || 0;    
                const actualFOCAmt = parseFloat(unit.Actual_FOC_Amount__c) || 0;

                base += rent;
                service += svc;
                marketing += mkt;
                rentFree += rf; 
                fitout += fo;   

                this.totalBaseRentBudgeted += actualRent;
                this.totalServiceChargeBudgeted += actualSvc;
                this.totalRentFreeBudgeted += actualrfAmt;
                this.totalFOCBudgeted += actualFOCAmt;
                this.totalMarketingAmountBudgeted += actualmktAmt;
                

            });

            this.totalBaseRentNumeric = base;
            this.totalServiceChargeNumeric = service;
            this.totalMarketingAmountNumeric = marketing;
            this.totalRentFreeAmountNumeric = rentFree; 
            this.totalFitoutContAmountNumeric = fitout; 

            const formatter = new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            this.totalBaseRent = 'AED ' + formatter.format(base);
            this.totalServiceCharge = 'AED ' + formatter.format(service);
            this.totalMarketingAmount = 'AED ' + formatter.format(marketing);
            this.totalRentFreeAmount = 'AED ' + formatter.format(rentFree); 
            this.totalFitoutContAmount = 'AED ' + formatter.format(fitout); 
        }

        const truncateTo = (num, decimals) => Math.floor(num * Math.pow(10, decimals)) / Math.pow(10, decimals);
        const toWords = (num) => {
            if (num >= 1_000_000_000) return `${truncateTo(num / 1_000_000_000, 2)} Billion`;
            if (num >= 1_000_000) return `${truncateTo(num / 1_000_000, 2)} Million`;
            if (num >= 1_000) return `${truncateTo(num / 1_000, 2)} Thousand`;
            return truncateTo(num, 2);
        };

        this.totalBaseRentWords = `${toWords(base)} AED`;
        this.totalServiceChargeWords = `${toWords(service)} AED`;
        this.totalMarketingAmountWords = `${toWords(marketing)} AED`;
        this.totalRentFreeAmountWords = `${toWords(rentFree)} AED`;
        this.totalFitoutContAmountWords = `${toWords(fitout)} AED`;
        this.buildApprovalSummary();
    }


    // -----------------------------------------------------
    // 10.1. VARIANCE CHECK HELPERS
    // -----------------------------------------------------

    checkBudgetVariance() {
        if (this.configureBy === 'Unit Level') {
            // TRUE if any unit rent differs from its original rent
            this.budgetVariance = this.selectedUnits.some(u => {
                const original = parseFloat(u.originalBaseRent) || 0;
                const current = parseFloat(u.Rent_Budget__c) || 0;
                return original !== current;
            });
        } else if (this.configureBy === 'Deal Level') {
            // TRUE if deal-level total rent differs from header desired rent
            const headerDesired = parseFloat(this.desiredRent) || 0;
            const currentTotal = parseFloat(this.totalBaseRentNumeric) || 0;
            this.budgetVariance = headerDesired !== currentTotal;
        }

        this.checkApprovalRequirement();
    }

    checkNatureVariance() {
        /* if (!this.leaseNature || !this.selectedUnits?.length) {
            this.natureVariance = false;
            this.checkApprovalRequirement();
            return;
        } */
        // TRUE if any unit’s nature differs from header lease nature
        this.natureVariance = this.selectedUnits.some(
            unit => (unit.Unit_Nature__c || '').toLowerCase() !== (this.leaseNature || '').toLowerCase()
        );
        this.checkApprovalRequirement();
    }


    // -----------------------------------------------------
    // 11. UTILITIES (Sorting, Toast, Approval)
    // -----------------------------------------------------

    sortData(fieldName, direction, data) {
        if (!data || data.length === 0) return;
        let parseData = JSON.parse(JSON.stringify(data));
        let isReverse = direction === 'asc' ? 1 : -1;

        parseData.sort((a, b) => {
            let valueA = a[fieldName];
            let valueB = b[fieldName];
            const nullA = (valueA === undefined || valueA === null || valueA === '');
            const nullB = (valueB === undefined || valueB === null || valueB === '');

            if (nullA && nullB) return 0;
            if (nullA) return 1 * isReverse;
            if (nullB) return -1 * isReverse;

            if (typeof valueA === 'number' || typeof valueB === 'number' || fieldName.includes('Area') || fieldName.includes('Days')) {
                valueA = isNaN(parseFloat(valueA)) ? 0 : parseFloat(valueA);
                valueB = isNaN(parseFloat(valueB)) ? 0 : parseFloat(valueB);
                return (valueA > valueB ? 1 : valueA < valueB ? -1 : 0) * isReverse;
            } 
            else {
                return (String(valueA).localeCompare(String(valueB))) * isReverse;
            }
        });
        
        this.units = parseData;
    }

    checkApprovalRequirement() {
        this.showApprovalRequired = this.budgetVariance || this.natureVariance;// || this.redemiseChange;
        console.log('PRE APPROVAL='+this.showApprovalRequired);
        this.buildApprovalSummary();
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    buildApprovalSummary() {
        let summary = `Pre-Approval Summary:\n\n`;
        summary += `Budget Variance: ${this.budgetVariance ? 'Yes' : 'No'}\n`;
        summary += `Nature Variance: ${this.natureVariance ? 'Yes' : 'No'}\n`;
        summary += `Redemise Change: ${this.redemiseChange ? 'Yes' : 'No'}\n\n`;
        summary += `Total Base Rent: AED ${this.totalBaseRentNumeric}\n`;
        summary += `Total Service Charge: AED ${this.totalServiceChargeNumeric}\n`;
        summary += `Total Marketing Amount: AED ${this.totalMarketingAmountNumeric}\n\n`;
        summary += `Unit-level Variances:\n`;
        this.selectedUnits.forEach(u => {
            const rentVariance = (parseFloat(u.Rent_Budget__c || 0) - parseFloat(u.originalBaseRent || 0)).toFixed(2);
            const natureVar = u.Unit_Nature__c !== this.leaseNature ? 'Yes' : 'No';
            summary += `Unit ${u.Unit_Code__c} | Original Rent: AED ${u.originalBaseRent || 0} | Current Rent: AED ${u.Rent_Budget__c || 0} | Rent Variance: AED ${rentVariance} | Nature Variance: ${natureVar}\n`;
        });

        this.approvalSummaryText = summary;
    }

    validateFields() {
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );
        
        let isValid = true;

        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        return isValid;
    }


}