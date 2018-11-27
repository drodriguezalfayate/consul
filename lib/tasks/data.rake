require 'securerandom'
require 'axlsx'

namespace :data do
  namespace :budgets do
    desc "Obtener un excel con los datos de todas las votaciones"
    task final_votes: :environment do
      p = Axlsx::Package.new
      wb = p.workbook

      Budget.order(id: :asc).each do |budget|
        wb.add_worksheet(name: "Presupuesto ID #{budget.id}") do |sheet|
          sheet.add_row [
            "DOCUMENTO USUARIO",
            "ID USUARIO",
            "ID PROPUESTA",
            "NOMBRE PROPUESTA",
            "FECHA CREACIÓN USUARIO",
            "FECHA DE VOTACIÓN"
          ]

          budget_ballot_lines = Budget::Ballot::Line.joins(ballot: :user).includes(ballot: :user).where("budget_ballots.budget_id = ?", budget.id).order("budget_ballot_lines.investment_id, users.document_number")
          budget_ballot_lines.each do |budget_ballot_line|
            current_document_number = nil
            current_document_number = budget_ballot_line.ballot.user.document_number if budget_ballot_line.ballot.user.document_number.present?

            sheet.add_row [
              current_document_number,
              budget_ballot_line.ballot.user_id,
              budget_ballot_line.investment_id,
              budget_ballot_line.investment.title,
              budget_ballot_line.ballot.user.created_at.strftime("%d/%m/%Y - %H:%M"),
              budget_ballot_line.created_at.strftime("%d/%m/%Y - %H:%M")
            ]
          end
        end
      end

      p.serialize("votos_presupuestos_participativos.xlsx")
    end

    desc "Obtener usuarios duplicados por DNI"
    task duplicated_users: :environment do
      p = Axlsx::Package.new
      wb = p.workbook

      documents = User.all.map(&:document_number).compact

      # Obtenemos los documentos de los usuarios repetidos
      duplicated_documents = documents.select{ |e| documents.count(e) > 1 }.uniq

      # Obtenemos los usuarios duplicados
      duplicated_users = User.where(document_number: duplicated_documents).order(:document_number, :id)
      wb.add_worksheet(name: "Usuarios duplicados") do |sheet|
        sheet.add_row [
          "DOCUMENTO",
          "ID USUARIO",
          "NOMBRE DEL USUARIO",
          "FECHA DE CREACIÓN",
          "ÚLTIMA FECHA DE INICIO DE SESIÓN"
        ]

        duplicated_users.each do |duplicated_user|
          sheet.add_row [
            duplicated_user.document_number,
            duplicated_user.id,
            duplicated_user.username,
            duplicated_user.created_at.strftime("%d/%m/%y"),
            duplicated_user.last_sign_in_at.try { strftime("%d/%m/%y") }
          ]
        end
      end

      p.serialize("usuarios_duplicados.xlsx")
    end

    desc "Obtener un excel con los datos de las votaciones de los usuarios duplicados"
    task duplicated_final_votes: :environment do
      p = Axlsx::Package.new
      wb = p.workbook

      Budget.order(id: :asc).each do |budget|
        wb.add_worksheet(name: "Presupuesto ID #{budget.id}") do |sheet|
          sheet.add_row [
            "DOCUMENTO USUARIO",
            "ID USUARIO",
            "ID PROPUESTA",
            "NOMBRE PROPUESTA",
            "FECHA CREACIÓN USUARIO",
            "FECHA DE VOTACIÓN"
          ]

          documents_and_ids = Budget::Ballot::Line.joins(ballot: :user).includes(ballot: :user).where("budget_ballots.budget_id = ?", budget.id).map{ |bbl| [bbl.ballot.user.document_number, bbl.ballot.user_id] }.uniq
          documents_groups = documents_and_ids.group_by(&:first)
          duplicated_documents = documents_groups.select{ |key, value| value.count > 1 }.keys.compact

          budget_ballot_lines = Budget::Ballot::Line.joins(ballot: :user).includes(ballot: :user).where("budget_ballots.budget_id = ? AND users.document_number IN (?)", budget.id, duplicated_documents).order("budget_ballots.user_id, budget_ballot_lines.investment_id")
          budget_ballot_lines_groups = budget_ballot_lines.group_by{ |bbl| bbl.ballot.user.document_number }

          budget_ballot_lines_groups.values.flatten.each do |budget_ballot_line|
            current_document_number = nil
            current_document_number = budget_ballot_line.ballot.user.document_number if budget_ballot_line.ballot.user.document_number.present?

            sheet.add_row [
              current_document_number,
              budget_ballot_line.ballot.user_id,
              budget_ballot_line.investment_id,
              budget_ballot_line.investment.title,
              budget_ballot_line.ballot.user.created_at.strftime("%d/%m/%Y - %H:%M"),
              budget_ballot_line.created_at.strftime("%d/%m/%Y - %H:%M")
            ]
          end
        end
      end

      p.serialize("votos_duplicados.xlsx")
    end
  end
end
