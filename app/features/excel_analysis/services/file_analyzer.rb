# frozen_string_literal: true

module Excel
  class FileAnalyzer
    def initialize(file_path)
      @file_path = file_path
    end

    def extract_data
      case File.extname(@file_path).downcase
      when '.xlsx'
        extract_xlsx_data
      when '.xls'
        extract_xls_data
      when '.csv'
        extract_csv_data
      else
        raise "Unsupported file format"
      end
    end

    private

    def extract_xlsx_data
      workbook = RubyXL::Parser.parse(@file_path)
      
      {
        format: 'xlsx',
        worksheets: workbook.worksheets.map { |ws| extract_worksheet_data(ws) },
        metadata: {
          created_at: workbook.created_time,
          modified_at: workbook.modified_time,
          application: workbook.application,
          worksheet_count: workbook.worksheets.count
        }
      }
    rescue => e
      Rails.logger.error("Excel file analysis failed: #{e.message}")
      { error: e.message, format: 'xlsx' }
    end

    def extract_xls_data
      # Use roo gem for older Excel files
      spreadsheet = Roo::Excel.new(@file_path)
      
      {
        format: 'xls',
        worksheets: spreadsheet.sheets.map { |sheet_name|
          spreadsheet.default_sheet = sheet_name
          extract_roo_worksheet_data(spreadsheet, sheet_name)
        },
        metadata: {
          worksheet_count: spreadsheet.sheets.count
        }
      }
    rescue => e
      Rails.logger.error("Excel file analysis failed: #{e.message}")
      { error: e.message, format: 'xls' }
    end

    def extract_csv_data
      require 'csv'
      
      data = []
      CSV.foreach(@file_path, headers: true) do |row|
        data << row.to_h
      end
      
      {
        format: 'csv',
        worksheets: [{
          name: 'Sheet1',
          data: data,
          row_count: data.count,
          column_count: data.first&.keys&.count || 0
        }],
        metadata: {
          worksheet_count: 1
        }
      }
    rescue => e
      Rails.logger.error("CSV file analysis failed: #{e.message}")
      { error: e.message, format: 'csv' }
    end

    def extract_worksheet_data(worksheet)
      data = []
      formulas = []
      
      worksheet.each_with_index do |row, row_index|
        next unless row
        
        row_data = []
        row.cells.each_with_index do |cell, col_index|
          next unless cell
          
          cell_data = {
            value: cell.value,
            datatype: cell.datatype,
            formula: cell.formula,
            row: row_index,
            col: col_index
          }
          
          row_data << cell_data
          
          # Collect formulas for analysis
          if cell.formula
            formulas << {
              formula: cell.formula,
              address: "#{RubyXL::Reference.ind2col(col_index)}#{row_index + 1}",
              row: row_index,
              col: col_index
            }
          end
        end
        
        data << row_data if row_data.any?
      end
      
      {
        name: worksheet.sheet_name,
        data: data,
        formulas: formulas,
        row_count: data.count,
        column_count: data.map(&:count).max || 0,
        formula_count: formulas.count
      }
    end

    def extract_roo_worksheet_data(spreadsheet, sheet_name)
      data = []
      formulas = []
      
      (spreadsheet.first_row..spreadsheet.last_row).each do |row|
        row_data = []
        (spreadsheet.first_column..spreadsheet.last_column).each do |col|
          cell_value = spreadsheet.cell(row, col)
          cell_formula = spreadsheet.formula(row, col)
          
          if cell_value || cell_formula
            cell_data = {
              value: cell_value,
              formula: cell_formula,
              row: row - 1, # Convert to 0-based
              col: col - 1  # Convert to 0-based
            }
            
            row_data << cell_data
            
            if cell_formula
              formulas << {
                formula: cell_formula,
                address: "#{('A'.ord + col - 1).chr}#{row}",
                row: row - 1,
                col: col - 1
              }
            end
          end
        end
        
        data << row_data if row_data.any?
      end
      
      {
        name: sheet_name,
        data: data,
        formulas: formulas,
        row_count: data.count,
        column_count: data.map(&:count).max || 0,
        formula_count: formulas.count
      }
    end
  end
end