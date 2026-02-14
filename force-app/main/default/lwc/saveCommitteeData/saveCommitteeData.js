import { LightningElement, track, api, wire } from 'lwc'; // Added 'wire'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Corrected Apex Controller imports to the expected file name
import saveCommitteeData from '@salesforce/apex/RETL_LeasingCommitteeReportController.saveCommitteeData'; 
import fetchCommitteeData from '@salesforce/apex/RETL_LeasingCommitteeReportController.fetchCommitteeData';
// NEW: Import the Apex method 'getOppLineData'
import getOppLineData from '@salesforce/apex/RETL_LeasingCommitteeReportController.getOppLineData'; 
import saveTemplateData from '@salesforce/apex/RETL_LeasingCommitteeReportController.saveTemplateData';

import getSavedTemplates from '@salesforce/apex/RETL_LeasingCommitteeReportController.getSavedTemplates';
import fetchTemplateData from '@salesforce/apex/RETL_LeasingCommitteeReportController.fetchTemplateData';

import getBenchmarkLeases from '@salesforce/apex/RETL_LeasingCommitteeReportController.getBenchmarkLeases';



// --- MOCK DATA DEFINITION (kept outside the class) ---
const INITIAL_LEFT_TABLE_DATA_CONFIG = {
    opDetails: [
        {
            key: "Operation Details",
            value: "SMOKEY BEACH by Kitoop is an established restaurant and shisha lounge operating in JBR and the Palm, Dubai. The concept will open in the former Gloofia unit with an international dining menu."
        }
    ],
    unit: [
        // The value for "Unit Name" will be dynamically replaced by Apex result
        { key: "Asset Name", value: "Yas Mall .." },
        { key: "Unit Name(s)", value: "Loading Unit Names..." }, 
        { key: "GLA (sqm)", value: "350.00" },
        { key: "Floor", value: "Ground Floor, Beachfront.." }
    ],
    tenantProfile: [
        { key: "Lease Manager", currentValue: "Gloofia FZ-LLC", futureValue: "Kitoop Hospitality" },
        { key: "Start Date", currentValue: "Restaurant", futureValue: "F&B / Shisha Lounge" },
        { key: "End Date", currentValue: "2018", futureValue: "2010" },
        { key: "Lease Period", currentValue: "5.50", futureValue: "17.00 (Est.)" },
        { key: "Brand", currentValue: "5.50", futureValue: "17.00 (Est.)" },
        { key: "Company", currentValue: "5.50", futureValue: "17.00 (Est.)" },
        { key: "Category", currentValue: "5.50", futureValue: "17.00 (Est.)" },
        { key: "Price Point", currentValue: "5.50", futureValue: "17.00 (Est.)" },
    ],
    tenantDueDilligence: [
        { key: "AML / KYC Status", value: "Green" },
        { key: "Trade License Status", value: "Valid" },
        { key: "Director Background", value: "Clean" }
    ],
    unitDueDilligence: [
        { key: "Last Rent Review", value: "2023" },
        { key: "ERV PSM", value: "3,000" },
        { key: "ERV GLA", value: "1,050,000" }
    ],
    leasingProgram: [
        { key: "Target Opening Date", value: "Q2 2026" },
        { key: "Term (Years)", value: "5" },
        { key: "Fit Out Period (Months)", value: "6 (Rent Free)" }
    ],
    securityDeposit: [
        { key: "Amount", value: "350,000 AED" },
        { key: "Terms", value: "3 months Gross Annual Rent" }
    ]
};

// INITIAL RENTAL VALUES (Used only if no saved data is found)
const INITIAL_RENTAL_VALUES = [
    ["1,750", "2,000", "2,250", "2,500", "2,750", "3,000"],
    ["612.5k", "700k", "787.5k", "875k", "962.5k", "1.05M"],
    ["350", "350", "350", "350", "350", "350"],
    ["735k", "822.5k", "910k", "1.00M", "1.09M", "1.23M"],
    ["8.0%", "8.0%", "8.0%", "8.0%", "8.0%", "8.0%"],
    ["11.7%", "10.0%", "8.9%", "8.0%", "7.3%", "6.7%"]
];

const INITIAL_RIGHT_TABLE_DATA_CONFIG = [
    { key: "BaseRentPSM", Base: "2,363", ERV: "3,000", Budget: "2,800", Passing: "2,500", rowClass: '' },
    { key: "BaseRent", Base: "827k", ERV: "1.05M", Budget: "980k", Passing: "875k", rowClass: 'total-bg' },
    { key: "ServiceChargePSM", Base: "300", ERV: "350", Budget: "350", Passing: "350", rowClass: '' },
    { key: "GrossAnnualRent", Base: "932k", ERV: "1.23M", Budget: "1.10M", Passing: "1.00M", rowClass: 'total-bg special-bg' },
    { key: "TOR", Base: "9.0%", ERV: "8.0%", Budget: "8.0%", Passing: "8.0%", rowClass: '' },
    { key: "OCR", Base: "8.9%", ERV: "10.0%", Budget: "10.0%", Passing: "10.0%", rowClass: '' },
];

const NEW_YEAR_DATA_TEMPLATE = [
    "3,250", // Base Rent PSM
    "1.13M", // Base Rent
    "350",  // Service Charge PSM
    "1.33M", // Gross Annual Rent
    "8.0%", // TOR (%)
    "6.3%"  // OCR (Fixed BR %)
];





export default class LeasingCommitteeReport extends LightningElement {

    showSaveAsModal = false;
    templateName = '';

    @track templates = [];
    @track selectedTemplateId;

    @api recordId;
    @track numYears = 6;
    @track pricingData;

    // State to manage loading/rendering
    @track isDataReady = false; 

    // IMPORTANT: leftTableData must be @track to allow dynamic updates from the wire service
    @track leftTableData = INITIAL_LEFT_TABLE_DATA_CONFIG;

    @track benchmarkOptions = [];
    @track selectedBenchmarkId;
    @track benchmarkRows = [];

    unitNamesLoaded = false;

    @track oppDetails; 
    @track lineItems = [];

    @wire(getBenchmarkLeases)
    wiredLeases({ error, data }) {
        if (data) {
            this.benchmarkOptions = data.map(lease => {
                return { label: lease.Name, value: lease.Id };
            });
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getSavedTemplates, { oppId: '$recordId' })
    wiredTemplates({ error, data }) {
        if (data) {
            this.templates = data.map(t => ({ label: t.templateName, value: t.templateId }));

            if (this.templates.length > 0 && !this.selectedTemplateId) {
                // Auto-select latest template
                this.selectedTemplateId = this.templates[0].value;
                console.log('this.selectedTemplateId: ' + this.selectedTemplateId + '');
                // Load template data
                this.handleTemplateChange({ detail: { value: this.selectedTemplateId }});
            }

        } else if (error) {
            console.error(error);
        }
    }


    async handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;

        if (!this.selectedTemplateId) return;

        try {
            const jsonData = await fetchTemplateData({ templateId: this.selectedTemplateId });
            const parsed = JSON.parse(jsonData);

            this.numYears = parsed.numYears ?? 6;
            this.pricingData = parsed.pricingData ?? parsed.pricingTable ?? [];

            const d = parsed.leftTableData || {};

            this.leftTableData = {
                unit: this.leftTableData.unit,
                opDetails: d.opDetails ?? INITIAL_LEFT_TABLE_DATA_CONFIG.opDetails,
                tenantProfile: d.tenantProfile ?? INITIAL_LEFT_TABLE_DATA_CONFIG.tenantProfile,                
                tenantDueDilligence: d.tenantDueDilligence ?? INITIAL_LEFT_TABLE_DATA_CONFIG.tenantDueDilligence,
                unitDueDilligence: d.unitDueDilligence ?? INITIAL_LEFT_TABLE_DATA_CONFIG.unitDueDilligence,
                leasingProgram: d.leasingProgram ?? INITIAL_LEFT_TABLE_DATA_CONFIG.leasingProgram,
                securityDeposit: d.securityDeposit ?? INITIAL_LEFT_TABLE_DATA_CONFIG.securityDeposit
            };
            this.benchmarkRows = parsed.benchmarkRows ?? [];


        } catch (error) {
            console.error('Error loading template', error);
        }
    }



    /**
     * Wires the result of getOppLineData (the concatenated unit names) to the component.
     */
    @wire(getOppLineData, { oppId: '$recordId' })
    wiredOppLineData({ error, data }) {
        if (this.unitNamesLoaded) return;

        if (data) {
            this.unitNamesLoaded = true;

            this.oppDetails = data.opp;
            this.lineItems = data.lines;

            // Pass the full wrapper object
            this.updateLeftTableData(data);

        } else if (error) {
            console.error('Error fetching line item data', error);
            this.unitNamesLoaded = true;

            this.updateLeftTableData({
                unitNames: 'ERROR: Could not load unit names.',
                GLA: '-',
                Floor: '-'
            });
        }
    }




    /**
     * Helper method to update the 'Unit Name' entry in the left panel data structure.
     * @param {string} unitNames - The concatenated string of unit names.
     */
    updateLeftTableData(wrapperData) {
    
        console.log('Wrapper Data:', JSON.stringify(wrapperData, null, 2));
        const unitListClone = [...this.leftTableData.unit];

        // Update Unit Name(s)
        const unitNameIndex = unitListClone.findIndex(item => item.key === "Unit Name(s)");
        if (unitNameIndex > -1) {
            unitListClone[unitNameIndex] = {
                ...unitListClone[unitNameIndex],
                value: wrapperData.unitNames
            };
        }

        // Update GLA
        const glaIndex = unitListClone.findIndex(item => item.key === "GLA (sqm)");
        if (glaIndex > -1) {
            unitListClone[glaIndex] = {
                ...unitListClone[glaIndex],
                value: wrapperData.GLA
            };
        }

        // Update Floor (optional)
        const FloorIndex = unitListClone.findIndex(item => item.key === "Floor");
        if (FloorIndex > -1 && wrapperData.floor) {
            unitListClone[FloorIndex] = {
                ...unitListClone[FloorIndex],
                value: wrapperData.floor
            };
        }

        // Update Floor (optional)
        const assetNameIndex = unitListClone.findIndex(item => item.key === "Asset Name");
        if (assetNameIndex > -1 && wrapperData.opp) {
            unitListClone[assetNameIndex] = {
                ...unitListClone[assetNameIndex],
                value: wrapperData.opp.Project__c
            };
        }

        this.leftTableData = {
            ...this.leftTableData,
            unit: unitListClone
        };
    }



    async connectedCallback() {
        if (this.recordId) {
            // Since Apex calls require a recordId, ensure it's available before loading
            await this.loadSavedData();
        } else {
            // Initialize with default data if no recordId (for local preview/testing)
            this.initializePricingData(null);
        }
    }

    /**
     * Attempts to fetch saved data from the Opportunity record.
     */
    async loadSavedData() {
        try {
            // Call the Apex method to fetch the saved JSON string
            const savedDataJson = await fetchCommitteeData({ oppId: this.recordId });

            if (savedDataJson) {
                // If data is found, parse it and initialize the component state
                const savedData = JSON.parse(savedDataJson);
                this.numYears = savedData.numYears;
                // Pass the fully structured saved data to the initializer
                this.initializePricingData(savedData.pricingTable);
                this.showToast('Success', 'Previous data loaded successfully.', 'success');
            } else {
                // If no saved data, initialize with default values
                this.initializePricingData(null);
            }
        } catch (error) {
            console.error('Data Load Error:', error);
            this.showToast('Error', 'Failed to load previous data. Initializing defaults.', 'error');
            // Fallback to defaults on error
            this.initializePricingData(null); 
        } finally {
            this.isDataReady = true;
        }
    }


    /**
     * Initializes pricingData, using loadedData if provided, otherwise uses defaults.
     * @param {Array} loadedData - The parsed pricingTable array from saved JSON.
     */
    initializePricingData(loadedData) {
        if (loadedData) {
            // Use saved data directly
            this.pricingData = loadedData;
        } else {
            // Use initial hardcoded data
            this.pricingData = INITIAL_RIGHT_TABLE_DATA_CONFIG.map((config, rowIndex) => {
                const rentalValues = INITIAL_RENTAL_VALUES[rowIndex].map((value, yearIndex) => ({
                    key: `Y${yearIndex + 1}-${config.key}`, // Unique key for rental value
                    value: value
                }));

                return {
                    ...config,
                    rentalValues: rentalValues,
                    key: config.key // Unique key for the row
                };
            });
        }
        this.isDataReady = true;
    }

    get yearHeaders() {
        const headers = [];
        for (let i = 1; i <= this.numYears; i++) {
            headers.push(`Y${i}`);
        }
        return headers;
    }

    handleAddYear() {
        this.numYears += 1;
        const newYearKey = `Y${this.numYears}`;
        
        // Deep clone to ensure reactivity is maintained
        const newPricingData = JSON.parse(JSON.stringify(this.pricingData));

        newPricingData.forEach((row, index) => {
            row.rentalValues.push({
                key: `${newYearKey}-${row.key}`,
                value: NEW_YEAR_DATA_TEMPLATE[index] || '-'
            });
        });

        this.pricingData = newPricingData;
    }

    handleInputChange(event) {
        const { value } = event.detail;
        const rowKey = event.target.dataset.rowKey;
        const yearIndex = parseInt(event.target.dataset.yearIndex, 10);

        // Deep clone the array for modification
        const newPricingData = JSON.parse(JSON.stringify(this.pricingData));

        // Find the row by its unique key (e.g., BaseRentPSM)
        const rowIndex = newPricingData.findIndex(row => row.key === rowKey);

        if (rowIndex > -1) {
            // Update the value in the nested rentalValues array at the correct year index
            newPricingData[rowIndex].rentalValues[yearIndex].value = value;
            
            // Reassign the whole array to trigger the LWC change detection and refresh the UI
            this.pricingData = newPricingData;
        }
    }

    /* async handleSave() {

        if (!this.selectedTemplateId) {
            this.showToast('Error', 'Please select a template to update.', 'error');
            return;
        }

        const dataToSave = {
            numYears: this.numYears,
            pricingTable: this.pricingData,
            leftTableData: this.leftTableData
        };

        const dataJson = JSON.stringify(dataToSave);

        try {
            await saveCommitteeData({
                templateId: this.selectedTemplateId,
                dataJson: dataJson
            });

            this.showToast('Success', 'Template updated successfully!', 'success');

        } catch (error) {
            console.error('Save error:', error);
            this.showToast('Error', error.body?.message || 'Template update failed.', 'error');
        }
    } */


    async handleSave() {
        if (!this.selectedTemplateId) {
            this.showToast('Error', 'Please select a template to update.', 'error');
            return;
        }

        const dataToSave = {
            numYears: this.numYears,
            pricingTable: this.pricingData,
            leftTableData: this.leftTableData,
            benchmarkRows: this.benchmarkRows  // ← NEW
        };

        const dataJson = JSON.stringify(dataToSave);

        try {
            await saveCommitteeData({
                templateId: this.selectedTemplateId,
                dataJson: dataJson
            });

            this.showToast('Success', 'Template updated successfully!', 'success');

        } catch (error) {
            console.error('Save error:', error);
            this.showToast('Error', error.body?.message || 'Template update failed.', 'error');
        }
    }



    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }


    // Modal 

    openSaveAsModal() {
        this.showSaveAsModal = true;
    }

    closeSaveAsModal() {
        this.showSaveAsModal = false;
        this.templateName = '';
    }

    handleTemplateNameChange(event) {
        this.templateName = event.target.value;
    }

    async handleSaveAs() {
        if (!this.templateName) {
            // You can add toast
            return;
        }

        const jsonData = JSON.stringify({
            numYears: this.numYears,
            pricingTable: this.pricingData
        });

        try {
            await saveTemplateData({
                templateName: this.templateName,
                dataJson: jsonData,
                oppId: this.recordId
            });

            // Close modal
            this.closeSaveAsModal();

            // Refresh dropdown list
            const updatedTemplates = await getSavedTemplates({ oppId: this.recordId });
            this.templates = updatedTemplates.map(t => ({
                label: t.templateName,
                value: t.templateId
            }));

            // Auto-select newly created template
            this.selectedTemplateId = newTemplateId;

            // Toast success
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Template saved successfully',
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error('Save As Error', error);
        }
    }



    handleOpDetailsChange(event) {
        const key = event.target.dataset.key;
        const newValue = event.target.value;

        // Clone opDetails array for reactivity
        const opDetailsClone = [...this.leftTableData.opDetails];

        // Find the matching item by key
        const index = opDetailsClone.findIndex(item => item.key === key);
        if (index > -1) {
            opDetailsClone[index] = {
                ...opDetailsClone[index],
                value: newValue
            };

            // Reassign leftTableData to trigger LWC reactivity
            this.leftTableData = {
                ...this.leftTableData,
                opDetails: opDetailsClone
            };
        }
    }


    handleBenchmarkChange(event) {
        this.selectedBenchmarkId = event.detail.value;

        // Find the selected lease
        const selectedLease = this.benchmarkOptions.find(b => b.value === this.selectedBenchmarkId);
        if (selectedLease) {
            // Add to benchmarkRows
            // You may need to fetch the full record for all fields if necessary
            this.benchmarkRows = [
                ...this.benchmarkRows,
                {
                    Id: selectedLease.value,
                    Name: selectedLease.label,
                    Unit: 'Example Unit',   // replace with actual Lease__c fields
                    GLA: 0,
                    Floor: '',
                    MN_Sales: 0,
                    Sales_PSM: 0,
                    BR_PSM: 0,
                    TORPercent: 0,
                    TOR: 0,
                    SC_PSM: 0,
                    OCRPercent: 0
                }
            ];
        }
    }


    handleBenchmarkInputChange(event) {
        const rowId = event.target.dataset.rowId;
        const field = event.target.dataset.field;
        const value = event.target.value;

        // Deep clone to preserve reactivity
        const updatedRows = JSON.parse(JSON.stringify(this.benchmarkRows));

        const rowIndex = updatedRows.findIndex(r => r.Id === rowId);
        if (rowIndex > -1) {
            updatedRows[rowIndex][field] = value;
            this.benchmarkRows = updatedRows;
        }
    }

    handleBenchmarkDelete(event) {
        const rowId = event.target.dataset.rowId;

        // Remove the row
        this.benchmarkRows = this.benchmarkRows.filter(row => row.Id !== rowId);
    }



}