const Promise = require("bluebird");
const AWS = require("aws-sdk");
const csvtojson = require("csvtojson");
const fs = require("fs");
const s3 = new AWS.S3();
const _ = require("lodash");
const s3_getObject = Promise.promisify(require("@deliverymanager/s3_fns").s3_getObject);
const client = new AWS.DynamoDB.DocumentClient();
const lambda_invoke = Promise.promisify(require("@deliverymanager/lambda_invoke").lambda_invoke);


exports.handler = async (event) => {
  console.log(event);
  class CustomError extends Error {
    constructor(...args) {
      super(...args);
      Error.captureStackTrace(this, CustomError);
      this.name = "CustomError";
    }
  }
  try {
    if (!event || !_.isObject(event) || !event.Records ||  !_.isArray(event.Records)) {
      throw new CustomError("invalid_params");
    }

    let addedCount = 0;
    let changedCount = 0;
    let bucketName, folderName, orderId;

    await Promise.mapSeries(event.Records, async (record) => {
      const key = record.s3.object.key;
      bucketName = record.s3.bucket.name;
      [folderName, fileName] = key.split("/");
      orderId = fileName.replace(".csv", "");
      console.log("data", bucketName, folderName, orderId);

      const parameters = {
        TableName: "orders",
        Key: {
          store_id: folderName,
          order_id: orderId
        }
      };
      return await client.update(parameters).promise();
    });

    if (!bucketName=='advertising-csvs' || !folderName=='csvs-folder'){
      throw new CustomError("invalid_params");
    }

    // here we are updating the List
    // _each find
    function UpdateList(uniquenewjson, uniqueoldjson) {
      _.each(uniquenewjson, function (newItem) {
        if (!newItem.VendorName) {
          return; // Skip this item if VendorName is empty
        }
        let index = _.findIndex(uniqueoldjson, { VendorName: newItem.VendorName });
        if (index !== -1) {
          if (_.some(_.values(_.omit(newItem, "VendorName")))) {
            _.assign(
              uniqueoldjson[index],
              _.pick(newItem, [
                "Address",
                "TKs",
                "Region",
                "Url",
                "Wholesale",
                "Retail",
                "Afm",
                "Gemi"
              ])
            );
            changedCount++;
          }
        } else {
          if (_.some(_.values(_.omit(newItem, "VendorName")))) {
            addedCount++;
            uniqueoldjson.push(newItem);
          }
        }
      });
      return _.orderBy(uniqueoldjson, ["VendorName"], ["asc"]);
    }

    // here we are uploading the list to s3 bucket
    async function uploadList(getList) {
      const params = {
        Bucket: "tempuploaded",
        Key: "outfile.json",
        Body: JSON.stringify(getList),
        ContentType: "application/json"
      };
      return await s3.upload(params).promise();
    }

    // here we get the uploaded Json
    async function getLiveCsv() {
      try {
        const json_data = await s3_getObject(
          {
            Bucket: "tempuploaded",
            Key: `outfile.json`
          },
          {
            timeout: 500,
            expiration_timeout: 1000
          }
        ).then((data) => JSON.parse(data));
        const vendors = json_data;
        return vendors.vendors;
      } catch (err) {
        if (err && err.code === "NotFound") {
          return Promise.resolve({
            vendors: []
          });
        }
        throw new CustomError(err);
      }
    }

    async function getNewCsvToJson() {
      try {
        const csv_data = await s3_getObject(
          {
            Bucket: bucketName,
            Key: `${folderName}/${orderId}.csv`
          },
          {
            timeout: 500,
            expiration_timeout: 1000
          }
        ).then((data) => {
          try {
            return data.toString(); // convert the buffer to a string
          } catch (e) {
            throw new Error("Failed to parse CSV data");
          }
        });

        const json_data = await csvtojson().fromString(csv_data);
        const vendors = json_data.map((item) =>
          _.pick(item, [
            "VendorName",
            "Address",
            "TKs",
            "Region",
            "Url",
            "Wholesale",
            "Retail",
            "Afm",
            "Gemi"
          ])
        );
        const jsonObject = { vendors };
        // const hasDuplicates =
        //   jsonObject.vendors.length !== _.uniqBy(jsonObject.vendors, "VendorName").length;
        // const groupedData = _.groupBy(jsonObject.vendors, 'VendorName');
        // const duplicates = _.filter(groupedData, (data) => data.length > 1);
        // console.log('Duplicates:', duplicates);

        return jsonObject.vendors;
      } catch (error) {
        console.log("Failed to retrieve data from S3:", error);
        return null;
      }
    }

    const getLocalJson = await getNewCsvToJson();
    if (getLocalJson) {
      const getUploadedJson = await getLiveCsv();
      if (getUploadedJson) {
        const vendors = UpdateList(getLocalJson, getUploadedJson);
        const jsonObject = { vendors };
        try {
          await lambda_invoke("slack_notify", '$LATEST', 'Event', {
            channel: "C6VE2A6PQ",
            text: `Λ: dm-format-business-registry-csv:\nNew added: ${addedCount},\nEdited-changed: ${changedCount}.`
        });
          // upload the JSON to an S3 bucket
          await uploadList(jsonObject);
          console.log("Successfully uploaded file to S3");
        } catch (error) {
          console.error("Error uploading file to S3:", error);
        }
      } else {
        console.log("Array is Empty invalid Path");
      }
    } else {
      console.log("Check your csv Path or check for Dublicates");
    }
  
    console.log("RequestId SUCCESS");
    return {
      success: true
    };
  } catch (err) {
    console.log("err", err);
    return {
      success: false
    };
  }
};
