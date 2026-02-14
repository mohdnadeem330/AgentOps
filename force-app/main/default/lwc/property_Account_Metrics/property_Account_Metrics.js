import { LightningElement, api, wire, track } from 'lwc';
import getCustomer360Summary from '@salesforce/apex/PropertyAccountMetrics.getCustomer360Summary';
import getLeasingSummary from '@salesforce/apex/PropertyAccountMetrics.getLeasingSummary';
import getOwnershipSummary from '@salesforce/apex/PropertyAccountMetrics.getOwnershipSummary';
import getFinancialInsights from '@salesforce/apex/PropertyAccountMetrics.getFinancialInsights';
import getEngagementSummary from '@salesforce/apex/PropertyAccountMetrics.getEngagementSummary';
import getMaintenanceAndDLPData from '@salesforce/apex/PropertyAccountMetrics.getMaintenanceAndDLPData';
import getFamilyRelationshipView from '@salesforce/apex/PropertyAccountMetrics.getFamilyRelationshipView';
import getOptionsAndUpgrades from '@salesforce/apex/PropertyAccountMetrics.getOptionsAndUpgrades';
import getBusinessCrossoverLOB from '@salesforce/apex/PropertyAccountMetrics.getBusinessCrossoverLOB';


export default class property_Account_Metrics extends LightningElement {
    @api recordId; 
    @track data;
    @track error;
    @track ownershipData;
    @track financialData; 
    @track engagementData;
    @track maintenanceData;
    @track familyData;
    @track csatEmoji;
    @track optionsData;
    @track lobData;
    @track customer360Data;

    // Display helpers for template (avoid conditional expressions in HTML)
    // Safe text fallback: return 'N/A' when null/undefined/empty after trim
    safeText(v) {
        const s = (v ?? '').toString().trim();
        return s.length ? s : 'N/A';
    }

    // Normalize booleans/flags that might arrive as string/boolean/null
    normalizeBoolean(v) {
        if (typeof v === 'boolean') return v;
        const s = (v ?? '').toString().trim().toLowerCase();
        if (s === 'true' || s === 'yes' || s === 'y' || s === '1') return true;
        if (s === 'false' || s === 'no' || s === 'n' || s === '0') return false;
        return false; // default to false when unknown/missing
    }

    get darnaDisplay() {
        // Accepts multiple possible keys coming from Apex/person account
        const raw =
            this.customer360Data?.darnaRegistered ??
            this.customer360Data?.DarnaRegistered__pc ??
            this.customer360Data?.darnaRegistered__pc;
        const isRegistered = this.normalizeBoolean(raw);
        return isRegistered ? 'Yes' : 'No';
    }

    get customerTypeDisplay() {
        return this.safeText(this.customer360Data?.customerType);
    }

    get customerSubTypeDisplay() {
        return this.safeText(this.customer360Data?.customerSubType);
    }

    get aldarSelectDisplay() {
        // Business rule per request:
        // - Show "No" when not VIP
        // - Show "Yes" when VIP, and when subtype available show "Yes (<subtype>)"
        // - Subtype should render "N/A" when blank (already handled via customerSubTypeDisplay)
        const type = this.customer360Data?.customerType?.trim()?.toUpperCase();
        const isVip = type === 'VIP';
        if (!isVip) {
            return 'No';
        }
        const tier = this.customerSubTypeDisplay; // already N/A-safe
        return tier !== 'N/A' ? `Yes (${tier})` : 'Yes';
    }

    /* ==================== Customer 360 Summary ==================== */
    @wire(getCustomer360Summary, { accountId: '$recordId' })
    wiredCustomer360({ error, data }) {
        if (data) {
            this.customer360Data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.customer360Data = undefined;
        }
    }

    get isVIP360Customer() {
        if (!this.customer360Data) return false;

        const type = this.customer360Data.customerType?.trim().toUpperCase();
        const subType = this.customer360Data.customerSubType?.trim().toUpperCase();

        return (
            type === 'VIP' &&
            ['VIP TIER 1', 'VVIP TIER 2', 'VVVIP TIER 3'].includes(subType)
        );
    }

    get vip360FillColor() {
        const subType = this.customer360Data?.customerSubType?.trim().toUpperCase();
        switch (subType) {
            case 'VIP TIER 1':
                return '#c5ef51'; 
            case 'VVIP TIER 2':
                return '#f8059b';
            case 'VVVIP TIER 3':
                return '#f8d407'; 
            default:
                return '#ffffff'; 
        }
    }

    /* ==================== Leasing Summary ==================== */
     @wire(getLeasingSummary, { accountId: '$recordId' })
    wiredLeasingSummary({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    get hasActiveLeases() {
        return this.data && this.data.activeLeases > 0;
    }

    // Format Leasing YTD value in AED with fallback
    get leaseValueYtdFormatted() {
        // Some Apex may return number or string; reuse AED formatter used elsewhere
        return this.formatAed(this.data?.leaseValue);
    }

    /* ==================== Ownership Summary ==================== */
    @wire(getOwnershipSummary, { accountId: '$recordId' })
    wiredOwnership({ error, data }) {
        if (data) {
            // create a copy and add formatted values and UI fallbacks
            const formatted = this.formatAed(data.totalSalesValue);
            const projectNamesDisplay =
                data.projectNames && String(data.projectNames).trim() !== '' ? data.projectNames : 'N/A';

            this.ownershipData = {
                ...data,
                totalSalesValueFormatted: formatted,
                projectNames: projectNamesDisplay
            };
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.ownershipData = undefined;
        }
    }

    // AED currency formatter and helper
    aedFormatter = new Intl.NumberFormat('en-AE', {
        style: 'currency',
        currency: 'AED',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });

    formatAed(value) {
        // Treat null / undefined / empty as missing
        if (value === null || value === undefined || value === '') {
            return 'N/A';
        }

        // Attempt to parse numeric value (handle strings that contain numbers)
        const n = Number(String(value).replace(/[^0-9.-]+/g, ''));
        if (!Number.isFinite(n)) return 'N/A';

        // Intl with en-AE generally yields "AED 1,234.56" — keep that formatting
        return this.aedFormatter.format(n);
    }

    /* ==================== Engagement Insights ==================== */
    @wire(getFinancialInsights, { accountId: '$recordId' })
    wiredFinancialInsights({ error, data }) {
        if (data) {
           // derive display value for CSAT: show blank when 0 or non-numeric
            /*const csatNum = Number(data.csatScore);
            const csatDisplay = Number.isFinite(csatNum) && csatNum !== 0 ? Math.round(csatNum) : 0;

            // derive display value for NPS: show blank when 0 or non-numeric
            const npsNum = Number(data.npsScore);
            const npsDisplay = Number.isFinite(npsNum) && npsNum !== 0 ? Math.round(npsNum) : 0;

            this.financialData = {
                ...data,
                csatScoreDisplay: csatDisplay,
                npsScoreDisplay: npsDisplay
            };
            this.error = undefined;*/

            const csatNum = Number(data.csatScore);
            const csatDisplay = Number.isFinite(csatNum) && csatNum !== 0 ? parseInt(csatNum) : 0;

            const npsNum = Number(data.npsScore);
            const npsDisplay = Number.isFinite(npsNum) && npsNum !== 0 ? parseInt(npsNum) : 0;

            this.financialData = {
            ...data,
            csatScoreDisplay: csatDisplay,
            npsScoreDisplay: Number.isFinite(npsDisplay) ? Math.floor(npsDisplay) : npsDisplay
            };
            this.error = undefined;


            // keep old emoji logic unused for now (retained for potential future use)
            const csat = parseFloat(data.csatScore);
            if (!isNaN(csat)) {
                if (csat < 2) {
                    this.csatEmoji = '😡';
                } else if (csat < 4) {
                    this.csatEmoji = '😞';
                } else if (csat < 6) {
                    this.csatEmoji = '😐';
                } else if (csat < 8) {
                    this.csatEmoji = '🙂';
                } else {
                    this.csatEmoji = '🤩';
                }
            } else {
                this.csatEmoji = '❓';
            }
        } else if (error) {
            this.error = error;
        }
    }

    /* ====================  Digital Engagement data ==================== */
    @wire(getEngagementSummary, { accountId: '$recordId' })
    wiredEngagement({ error, data }) {
        if (data) {
            const plainData = JSON.parse(JSON.stringify(data));
            // Apply UI fallbacks: if KYC status blank, show 'N/A'; also keep formatted dates fallbacks
            const kycStatusDisplay =
                plainData.kycStatus && String(plainData.kycStatus).trim() !== '' ? plainData.kycStatus : 'N/A';

            this.engagementData = {
                ...plainData,
                kycStatus: kycStatusDisplay,
                // Display in the viewing user's local time zone
                lastLogin: plainData.lastLogin ? (plainData.lastLogin) : 'N/A',
                kycdate: plainData.kycdate ? this.formatDateUserTZ(plainData.kycdate) : 'N/A',
                fastTrackCompletion: plainData.fastTrackCompletion ? this.formatDateUserTZ(plainData.fastTrackCompletion) : 'N/A'
            };
            console.log('Engagement Data after clone:', JSON.stringify(this.engagementData));
        } else if (error) {
            this.error = error;
        }
    }

    // Safe getters for Digital Engagement fields to avoid undefined errors in template
    get engagementLastLogin() {
        return this.engagementData?.lastLogin ?? 'N/A';
    }

    get engagementKycStatus() {
        return this.engagementData?.kycStatus ?? 'N/A';
    }

    get engagementKycDate() {
        return this.engagementData?.kycdate ?? 'N/A';
    }

    get engagementFastTrackCompletion() {
        return this.engagementData?.fastTrackCompletion ?? 'N/A';
    }

   // Formats a datetime string to the viewing user's local browser time zone
   formatDateUserTZ(dateString) {
        if (!dateString) {
            return 'N/A';
        }

        // Expecting ISO/UTC from Apex; new Date will treat it as UTC if it has 'Z'
        const date = new Date(dateString);
        if (isNaN(date.getTime())) {
            return 'N/A';
        }

        // Use the browser's local time zone for the logged-in user
        // Example output: 16 Dec 2025, 02:15:30 PM
        return new Intl.DateTimeFormat('en-GB', {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        }).format(date);
    }


    get formattedCustomerVertical() {
        return this.engagementData?.customerVertical
            ? this.engagementData.customerVertical.replaceAll(';', ', ')
            : 'N/A';
    }

    /* ==================== Maintenance & DLP Summary ==================== */
    @wire(getMaintenanceAndDLPData, { accountId: '$recordId' })
    wiredMaintenanceDLP({ error, data }) {
        if (data) {
            this.maintenanceData = data;
        } else if (error) {
            this.error = error;
        }
    }

    /* ==================== Family & Relationship View ==================== */
    @wire(getFamilyRelationshipView, { accountId: '$recordId' })
    wiredFamilyRelationship({ error, data }) {
        if (data) {
            this.familyData = data;
        } else if (error) {
            this.error = error;
        }
    }

    // Normalized display getters for Family section
    get spouseNamesDisplay() {
        const v = this.familyData?.spouseNames;
        return v && String(v).trim().length ? v : 'N/A';
    }

    get childrenNamesDisplay() {
        const v = this.familyData?.childrenNames;
        return v && String(v).trim().length ? v : 'N/A';
    }

    /* ==================== Option & Upgrade ==================== */
    @wire(getOptionsAndUpgrades, { accountId: '$recordId' })
    wiredOptions({ error, data }) {
        if (data) {
            this.optionsData = data;
        } else if (error) {
            console.error('Error loading Options and Upgrades', error);
        }
    }

    /* ==================== Other Lines of Business (LOB) ==================== */
    @wire(getBusinessCrossoverLOB, { accountId: '$recordId' })
    wiredLOB({ error, data }) {
        if (data) {
            this.lobData = data;
        } else if (error) {
            this.error = error;
        }
    }

    get lobListDisplay() {
        return this.lobData && this.lobData.length > 0
            ? this.lobData.join(', ')
            : 'N/A';
    }

    get errorMessage() {
        return this.error && this.error.body ? this.error.body.message : 'Unknown error';
    }

    get vipTagStyle() {
        if (!this.customer360Data || !this.customer360Data.customerSubType) {
            return '';
        }
        const subtype = this.customer360Data.customerSubType.toLowerCase();

        let color = '#ccc'; // default grey

        if (subtype.includes('vip tier 1')) {
            color = '#FFD700'; // gold
        } else if (subtype.includes('vip tier 2')) {
            color = '#FF69B4'; // pink
        } else if (subtype.includes('vip tier 3')) {
            color = '#87CEEB'; // sky blue
        }

        return `background-color:${color};`;
    }
}