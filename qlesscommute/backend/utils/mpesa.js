const axios = require('axios');
const { pool } = require('../config/database');

class MpesaService {
  constructor() {
    this.consumerKey = process.env.MPESA_CONSUMER_KEY;
    this.consumerSecret = process.env.MPESA_CONSUMER_SECRET;
    this.businessShortCode = process.env.MPESA_BUSINESS_SHORT_CODE;
    this.passkey = process.env.MPESA_PASSKEY;
    this.callbackUrl = process.env.MPESA_CALLBACK_URL;
    this.baseUrl = 'https://sandbox.safaricom.co.ke'; // Use production URL for live
  }

  // Generate OAuth access token
  async generateAccessToken() {
    try {
      const auth = Buffer.from(`${this.consumerKey}:${this.consumerSecret}`).toString('base64');
      
      const response = await axios.get(
        `${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
        {
          headers: {
            'Authorization': `Basic ${auth}`
          }
        }
      );

      return response.data.access_token;
    } catch (error) {
      console.error('Error generating access token:', error.response?.data || error.message);
      throw new Error('Failed to generate M-Pesa access token');
    }
  }

  // Generate password for STK Push
  generatePassword() {
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, -3);
    const password = Buffer.from(`${this.businessShortCode}${this.passkey}${timestamp}`).toString('base64');
    
    return { password, timestamp };
  }

  // Initiate STK Push
  async initiateSTKPush(phoneNumber, amount, accountReference, transactionDesc) {
    try {
      const accessToken = await this.generateAccessToken();
      const { password, timestamp } = this.generatePassword();

      // Format phone number (remove leading 0 and add 254)
      const formattedPhone = phoneNumber.startsWith('0') 
        ? `254${phoneNumber.substring(1)}` 
        : phoneNumber.startsWith('254') 
        ? phoneNumber 
        : `254${phoneNumber}`;

      const stkPushData = {
        BusinessShortCode: this.businessShortCode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: 'CustomerPayBillOnline',
        Amount: Math.round(amount),
        PartyA: formattedPhone,
        PartyB: this.businessShortCode,
        PhoneNumber: formattedPhone,
        CallBackURL: this.callbackUrl,
        AccountReference: accountReference,
        TransactionDesc: transactionDesc
      };

      const response = await axios.post(
        `${this.baseUrl}/mpesa/stkpush/v1/processrequest`,
        stkPushData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        success: true,
        data: response.data,
        checkoutRequestId: response.data.CheckoutRequestID,
        merchantRequestId: response.data.MerchantRequestID
      };
    } catch (error) {
      console.error('STK Push error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.errorMessage || 'STK Push failed'
      };
    }
  }

  // Query STK Push status
  async querySTKPushStatus(checkoutRequestId) {
    try {
      const accessToken = await this.generateAccessToken();
      const { password, timestamp } = this.generatePassword();

      const queryData = {
        BusinessShortCode: this.businessShortCode,
        Password: password,
        Timestamp: timestamp,
        CheckoutRequestID: checkoutRequestId
      };

      const response = await axios.post(
        `${this.baseUrl}/mpesa/stkpushquery/v1/query`,
        queryData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('STK Push query error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.errorMessage || 'Query failed'
      };
    }
  }

  // Process M-Pesa callback
  async processCallback(callbackData) {
    try {
      const { Body } = callbackData;
      const stkCallback = Body.stkCallback;
      
      const checkoutRequestId = stkCallback.CheckoutRequestID;
      const merchantRequestId = stkCallback.MerchantRequestID;
      const resultCode = stkCallback.ResultCode;
      const resultDesc = stkCallback.ResultDesc;

      // Update transaction status in database
      if (resultCode === 0) {
        // Payment successful
        const callbackMetadata = stkCallback.CallbackMetadata;
        const amount = callbackMetadata.Item.find(item => item.Name === 'Amount').Value;
        const mpesaReceiptNumber = callbackMetadata.Item.find(item => item.Name === 'MpesaReceiptNumber').Value;
        const transactionDate = callbackMetadata.Item.find(item => item.Name === 'TransactionDate').Value;
        const phoneNumber = callbackMetadata.Item.find(item => item.Name === 'PhoneNumber').Value;

        // Update transaction as completed
        await pool.execute(
          `UPDATE transactions 
           SET status = 'completed', mpesa_code = ?, updated_at = NOW() 
           WHERE checkout_request_id = ?`,
          [mpesaReceiptNumber, checkoutRequestId]
        );

        // Update ride status
        await pool.execute(
          `UPDATE rides r 
           JOIN transactions t ON r.id = t.ride_id 
           SET r.status = 'confirmed' 
           WHERE t.checkout_request_id = ?`,
          [checkoutRequestId]
        );

        return {
          success: true,
          status: 'completed',
          mpesaCode: mpesaReceiptNumber
        };
      } else {
        // Payment failed
        await pool.execute(
          `UPDATE transactions 
           SET status = 'failed', updated_at = NOW() 
           WHERE checkout_request_id = ?`,
          [checkoutRequestId]
        );

        return {
          success: false,
          status: 'failed',
          error: resultDesc
        };
      }
    } catch (error) {
      console.error('Callback processing error:', error);
      return {
        success: false,
        error: 'Callback processing failed'
      };
    }
  }
}

module.exports = new MpesaService();