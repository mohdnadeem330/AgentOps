import { LightningElement, api, track } from 'lwc';

export default class ComplianceRiskBreakdown extends LightningElement {
    /** 
     * Full API response as JSON string or object from Flow 
     * (e.g., {"applicationName": "...", "results": { ... }})
     */
    @api apiResponse;// = { "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "89bcbd80-b09c-11f0-a05c-02bfc88b8315", "results": { "riskScore": 11, "riskLevel": "Low", "riskUpdateDateTime": "2025-10-24T09:44:42.141443+04:00", "bank_risk": "Medium", "birth_risk": "Low", "customer_risk": "High", "nationality_risk": "Low", "exposure_risk": "Medium", "quantum_risk": "Low", "residency_risk": "Medium", "screening_risk": "High", "fund_risk": "Low", "trans_risk": "Medium", "bank_score": 7.5, "birth_score": 3.2, "customer_score": 9.1, "nationality_score": 2.8, "exposure_score": 6.4, "quantum_score": 4.0, "residency_score": 5.7, "screening_score": 8.9, "fund_score": 3.5, "trans_score": 6.0 } };

    @track summary = {};
    @track data = [];

    showTable = false;

    get toggleButtonLabel() {
        return this.showTable ? 'Hide Breakdown' : 'Show Breakdown';
    }

    get toggleIcon() {
        return this.showTable ? 'utility:hide' : 'utility:preview';
    }

    handleToggle() {
        this.showTable = !this.showTable;
    }


    columns = [
        { label: 'S.No', fieldName: 'id', type: 'number', initialWidth: 70 },
        { label: 'Risk Category', fieldName: 'category', type: 'text'},
        { label: 'Risk Level', fieldName: 'level', type: 'text' },
        //{ label: 'Risk Icon', fieldName: 'icon', type: 'text', initialWidth: 110 },
        { label: 'Risk Score', fieldName: 'score', type: 'number' }
    ];

    get riskBadgeClass() {
        if (!this.summary.riskLevel) return 'slds-badge';
        switch (this.summary.riskLevel.toLowerCase()) {
            case 'high':
                return 'slds-badge slds-theme_error';
            case 'medium':
                return 'slds-badge slds-theme_warning';
            case 'low':
                return 'slds-badge slds-theme_success';
            default:
                return 'slds-badge slds-theme_info';
        }
    }

    get formattedDate() {
        if (!this.summary.riskUpdateDateTime) return '';
        try {
            return new Date(this.summary.riskUpdateDateTime).toLocaleString();
        } catch {
            return this.summary.riskUpdateDateTime;
        }
    }

    connectedCallback() {
        try {
            this.parseResponse();
        } catch (e) {
            console.error('Error parsing API response:', e);
        }
    }

    parseResponse() {
        if (!this.apiResponse) {
            console.warn('No API response provided.');
            return;
        }

        let parsed;
        if (typeof this.apiResponse === 'string') {
            parsed = JSON.parse(this.apiResponse);
        } else {
            parsed = this.apiResponse;
        }

        // Basic validation
        if (!parsed.results) {
            console.warn('Response missing "results" section.');
            return;
        }

        const res = parsed.results;

        // Populate summary info
        this.summary = {
            riskScore: res.riskScore,
            riskLevel: res.riskLevel,
            riskUpdateDateTime: res.riskUpdateDateTime
        };

        // Build datatable rows
        this.data = [
            { id: 1,  category: 'Bank Country',           level: this.getBadgeHTML(res.bank_risk) + ' ' + res.bank_risk,      score: res.bank_score, icon : this.getBadgeHTML(res.bank_risk) },
            { id: 2,  category: 'Country of Birth',       level: this.getBadgeHTML(res.birth_risk) + ' ' + res.birth_risk,     score: res.birth_score, icon : this.getBadgeHTML(res.birth_risk) },
            { id: 3,  category: 'Customer Type',          level: this.getBadgeHTML(res.customer_risk) + ' ' + res.customer_risk,  score: res.customer_score, icon : this.getBadgeHTML(res.customer_risk) },
            { id: 4,  category: 'Nationality',            level: this.getBadgeHTML(res.nationality_risk) + ' ' + res.nationality_risk, score: res.nationality_score, icon : this.getBadgeHTML(res.nationality_risk) },
            { id: 5,  category: 'Property Value',         level: this.getBadgeHTML(res.exposure_risk) + ' ' + res.exposure_risk,  score: res.exposure_score, icon : this.getBadgeHTML(res.exposure_risk) },
            { id: 6,  category: 'Quantum Fund',           level: this.getBadgeHTML(res.quantum_risk) + ' ' + res.quantum_risk,   score: res.quantum_score, icon : this.getBadgeHTML(res.quantum_risk) },
            { id: 7,  category: 'Residency',              level: this.getBadgeHTML(res.residency_risk) + ' ' + res.residency_risk, score: res.residency_score, icon : this.getBadgeHTML(res.residency_risk) },
            { id: 8,  category: 'Screening',              level: this.getBadgeHTML(res.screening_risk) + ' ' + res.screening_risk, score: res.screening_score, icon : this.getBadgeHTML(res.screening_risk) },
            { id: 9,  category: 'Source of Fund',         level: this.getBadgeHTML(res.fund_risk) + ' ' + res.fund_risk,      score: res.fund_score, icon : this.getBadgeHTML(res.fund_risk) },
            { id: 10, category: 'Transaction Value',      level: this.getBadgeHTML(res.trans_risk) + ' ' + res.trans_risk,     score: res.trans_score, icon : this.getBadgeHTML(res.trans_risk) }
        ];
    }

    getBadgeHTML(level) {
        if (!level) return '';
        let icon = '';
        if (level) {
            switch (level?.toLowerCase()) {
                case 'high': icon = '🔴'; break;
                case 'medium': icon = '🟠'; break;
                case 'low': icon = '🟡'; break;
                case 'very low': icon = '🟢'; break;
            }
         }
        return icon;
    }
}