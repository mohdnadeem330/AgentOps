import { LightningElement, api, track } from 'lwc';

export default class LeasingCommitteeTemplate extends LightningElement {
    @api recordId; // Opportunity ID will be passed here

    // --- Dynamic Column Control & Reactive Properties ---
    // Must be @track for component to re-render when changed
    @track numYears = 6; 
    @track rightTableData; 
    
    // --- File Upload Properties ---
    uploadedFileId;
    filePreviewUrl;
    acceptedFormats = ['.png', '.jpg', '.jpeg', '.pdf'];

    // --- Left Table Data (Read-only after init) ---
    leftTableData = {
        unit: [
            { key: 'UNIT # - Area', value: 'G-G6', class: 'bold-value' },
            { key: 'Asset', value: 'Eastern Mangroves' },
            { key: 'Floor', value: 'Ground' },
            { key: 'Leasing Cycle', value: 'Operational' },
            { key: 'Asset Manager', value: 'Chris' },
        ],
        // Updated to use currentValue/futureValue for clarity in a two-column layout
        tenantProfile: [
            { key: 'Lease Manager', currentValue: 'Current', futureValue: 'Chris' }, 
            { key: 'Start Date', currentValue: '28 Sep 2025', futureValue: '28 Sep 2025' }, 
            { key: 'End Date', currentValue: '27 Sep 2030', futureValue: '27 Sep 2030' },
            { key: 'Lease Period', currentValue: '5 yrs', futureValue: '5 yrs' },
            { key: 'Brand', currentValue: 'N/A', futureValue: 'Smokey Beach' },
            { key: 'Company', currentValue: 'N/A', futureValue: 'Kitoop' },
            { key: 'Category', currentValue: 'N/A', futureValue: 'F&B' },
            { key: 'Price Point', currentValue: 'N/A', futureValue: '120+' },
        ],
        tenantDueDilligence: [
            { key: 'Type', value: 'Established UAE Company' },
            { key: 'Units In The UAE', value: '2' },
            { key: 'Units in Abu Dhabi', value: '0' },
            { key: 'Assets in portfolio', value: '5+' },
        ],
        financialConditions: [
            { key: 'Total Unit Turnover', value: '31,988', class: 'bold-value' },
            { key: 'Units in the UAE', value: '2' },
            { key: 'Units under the UAE', value: '0' },
            { key: 'Assets in portfolio', value: '5+' },
        ],
        unitDueDilligence: [
            { key: 'HoD to RDD', value: 'N/A' },
            { key: 'HO condition to RDD', value: 'As is' },
            { key: 'HO condition to tenant', value: 'Shell & Core' },
            { key: 'Unit modifications', value: 'Shell & Core' },
            { key: 'Mn LL Works', value: '30K' },
            { key: 'Mn Value uplift', value: '0.0' },
        ],
        leasingProgram: [
            { key: 'Fit-out duration incl. design', value: '230' },
            { key: 'Handover to tenant', value: '1 May 2025' },
            { key: 'on site Fit Out works period', value: '150' },
            { key: 'Opening date', value: '28 Sep 2025' },
        ],
        securityDeposit: [
            { key: 'Payments', value: '25% of Gross Rent Y1' },
            { key: 'Method', value: 'Quarterly payment in advance' },
            { key: 'Term', value: 'Direct Debit' },
            { key: 'Grace', value: 'Lease 12m' },
        ],
    };

    // Private property holding the initial flat data structure for transformation.
    // Y6 data added for completeness to match the initial numYears = 6.
    _initialPricingData = [
        { key: 'Base Rent psm', Base: '2,363', ERV: '700', Budget: '0', Y1: '1,250', Y2: '1,313', Y3: '1,378', Y4: '1,447', Y5: '1,519', Y6: '1,595', PricePoint: 'Negotiated', class: 'data-row pricing-data-row' },
        { key: 'Turn Over Rent %', Base: '8%', ERV: '10%', Budget: '0%', Y1: '10%', Y2: '10%', Y3: '10%', Y4: '10%', Y5: '10%', Y6: '10%', PricePoint: '10%', class: 'data-row pricing-data-row' },
        { key: 'Turn Over Rent psm', Base: '194', ERV: '0', Budget: '0', Y1: '1,590', Y2: '1,670', Y3: '1,750', Y4: '2,027', Y5: '2,302', Y6: '2,577', PricePoint: '3,821', class: 'data-row pricing-data-row' },
        { key: 'Income psm', Base: '2,557', ERV: '700', Budget: '0', Y1: '2,840', Y2: '2,983', Y3: '3,130', Y4: '3,474', Y5: '3,821', Y6: '4,168', PricePoint: '3,821', class: 'data-row pricing-data-row total-row' },
        { key: 'Income AED', Base: '1,965,117', ERV: '537,527', Budget: '0', Y1: '2,003,422', Y2: '2,203,808', Y3: '2,424,189', Y4: '2,666,608', Y5: '2,933,269', Y6: '3,226,596', PricePoint: '2,933,269', class: 'data-row pricing-data-row' },
        { key: 'Services Charges psm', Base: '300', ERV: '300', Budget: '300', Y1: '300', Y2: '308', Y3: '315', Y4: '323', Y5: '331', Y6: '339', PricePoint: '331', class: 'data-row pricing-data-row' },
        { key: 'Sales psm', Base: '31,968', ERV: '0', Budget: '0', Y1: '28,100', Y2: '28,710', Y3: '31,581', Y4: '34,739', Y5: '38,213', Y6: '42,034', PricePoint: '38,213', class: 'data-row pricing-data-row' },
        { key: 'OCR %', Base: '8.9%', ERV: '0.0%', Budget: '0.0%', Y1: '11.1%', Y2: '11.0%', Y3: '11.0%', Y4: '10.9%', Y5: '10.9%', Y6: '10.8%', PricePoint: '10.9%', class: 'data-row pricing-data-row' },
        { key: 'Base Rent increase', Base: '5%', ERV: '0%', Budget: '0%', Y1: '5.0%', Y2: '5.0%', Y3: '5.0%', Y4: '5.0%', Y5: '5.0%', Y6: '5.0%', PricePoint: '5.0%', class: 'data-row pricing-data-row' },
        { key: 'Services Charges incr', Base: '0%', ERV: '0%', Budget: '0%', Y1: '0.0%', Y2: '2.5%', Y3: '2.5%', Y4: '2.5%', Y5: '2.5%', Y6: '2.5%', PricePoint: '-', class: 'data-row pricing-data-row' }
    ];

    connectedCallback() {
        this.transformPricingData();
    }
    
    /**
     * Getter to create the list of dynamic year labels (Y1, Y2, Y3, etc.)
     * This is used by the HTML template for headers.
     */
    get years() {
        const yearLabels = [];
        for (let i = 1; i <= this.numYears; i++) {
            yearLabels.push(`Y${i}`);
        }
        return yearLabels;
    }
    
    /**
     * Transforms the initial flat pricing data (e.g., row.Y1) into the LWC-compatible 
     * nested array structure (row.rentalValues). This must be done once on load.
     */
    transformPricingData() {
        const years = this.years;
        // Deep clone the initial data to work with
        const originalPricing = JSON.parse(JSON.stringify(this._initialPricingData));
        
        const transformedPricing = originalPricing.map(row => {
            const rentalValues = [];
            // Iterate over the expected year keys (Y1..Y6)
            years.forEach(yearKey => {
                // If the year key exists in the current row, extract it and add it to rentalValues
                if (Object.prototype.hasOwnProperty.call(row, yearKey)) {
                    rentalValues.push({ key: yearKey, value: row[yearKey] });
                    // Delete the old flat key to keep the row clean
                    delete row[yearKey];
                }
            });
            
            // Assign the new nested array to the row
            row.rentalValues = rentalValues;
            return row;
        });

        // Update the reactive property with the transformed data
        this.rightTableData = { pricing: transformedPricing };
    }

    /**
     * Handles the click event for the "Add Year" button.
     * 1. Increments the year count.
     * 2. Adds a new year column data point to every row's rentalValues array.
     */
    handleAddYear() {
        // 1. Calculate new year details
        this.numYears = this.numYears + 1;
        const newYearLabel = `Y${this.numYears}`;

        // 2. Clone the pricing array for mutation (essential for LWC reactivity)
        let updatedPricingData = JSON.parse(JSON.stringify(this.rightTableData.pricing));

        // 3. Update each row with the new year column data
        updatedPricingData = updatedPricingData.map(row => {
            // Add the new rental value object to the nested array
            row.rentalValues.push({
                key: newYearLabel,
                // New columns start with a default value of '0.00'
                value: '0.00' 
            });
            return row;
        });

        // 4. Update the reactive property. Re-assigning the whole object triggers re-render.
        this.rightTableData = { ...this.rightTableData, pricing: updatedPricingData };

        console.log(`Successfully added new year column: ${newYearLabel}`);
    }


    /**
     * Handles the successful completion of the file upload.
     * The file is automatically associated with the recordId (Opportunity) by the platform.
     */
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            // Store the ContentVersionId to track the uploaded file
            this.uploadedFileId = uploadedFiles[0].contentVersionId;
            
            // Construct the Salesforce URL for file preview/download
            this.filePreviewUrl = `/sfc/servlet.shepherd/version/download/${this.uploadedFileId}`;

            console.log(`Floor Plan uploaded successfully! ContentVersionId: ${this.uploadedFileId}`);
        } else {
            this.uploadedFileId = '';
            this.filePreviewUrl = '';
            console.error('File upload failed or no file was returned.');
        }
    }
}