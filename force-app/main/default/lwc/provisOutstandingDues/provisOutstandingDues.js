import { LightningElement, api, track } from 'lwc';
import getOutstandingFromERP from '@salesforce/apexContinuation/ProvisOutstandingDuesController.getOutstandingFromERP';

export default class OutstandingDues extends LightningElement {
    @api recordId;
    @track computedDues = [];
    @track error = null;
    @track lastUpdated = null;
    isLoading = false;

    labels = {
        totalOutstandingAmt: 'Total Outstanding Amount',
        totalPenaltyAmt: 'Penalty Amount',
        paidAmount: 'Paid Amount',
        pendingOutstanding: 'Pending Outstanding'
    };

    fetchOutstandingDues() {
        this.isLoading = true;
        getOutstandingFromERP({ recordId: this.recordId })
            .then((result) => {
                this.isLoading = false;
                if (result) {
                    let parsedData2 = JSON.parse(result);

                    if (parsedData2?.success && Array.isArray(parsedData2?.results) && parsedData2.results.length > 0) {
                        this.computeFormattedDues(parsedData2.results[0]);
                        
                    } else {
                        this.error = 'No Matching Information for the Request';
                    }
                    this.updateTimestamp();
                } else {
                    this.error = 'Invalid response from server!';
                    
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.error = 'Error fetching dues: ' + (error.body?.message || error.message);

            });
            
    }

    computeFormattedDues(dues) {
                console.log('Parsed dues object:', dues);
         const penalty = parseFloat(dues["total_penalty_amount"] || 0);
    const pending = parseFloat(dues["pending_outstanding"] || 0);
    const totalOutstanding = pending + penalty;
    console.log('totalOutstanding::', totalOutstanding);
        const computedDues = [
        {
            key: 'totalOutstandingAmt',
            label: this.labels.totalOutstandingAmt,
            value: this.formatCurrency(totalOutstanding),
            icon: "💰",
            badgeClass: "danger"
        },
        {
            key: 'totalPenaltyAmt',
            label: this.labels.totalPenaltyAmt,
            value: this.formatCurrency(penalty),
            icon: "⚠️",
            badgeClass: "warning"
        },
        {
            key: 'paidAmount',
            label: this.labels.paidAmount,
            value: this.formatCurrency(dues["paid_amount"]),
            icon: "✅",
            badgeClass: "success"
        },
        {
            key: 'pendingOutstanding',
            label: this.labels.pendingOutstanding,
            value: this.formatCurrency(pending),
            icon: "🔴",
            badgeClass: "warning"
        }
    ];

    this.computedDues = computedDues;
    }

    formatCurrency(value) {
    const number = parseFloat(value);
    return !isNaN(number) ? `AED ${number.toFixed(2)}` : '-';
    }

    updateTimestamp() {
        this.lastUpdated = new Date().toLocaleString();
    }

    handleRefresh() {
        this.error = null;
        this.computedDues = [];
        this.fetchOutstandingDues();
    }
}