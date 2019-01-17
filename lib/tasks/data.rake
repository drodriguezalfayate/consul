require 'securerandom'
require 'axlsx'

namespace :data do
  namespace :budgets do
    desc "Comprobación final de que no quedan usuarios duplicados"
    task check_duplicated_users: :environment do
      documents = User.all.map(&:document_number).compact
      documents.count - documents.uniq.count
      duplicated = documents.select{ |e| documents.count(e) > 1 }.uniq

      if duplicated.present?
        puts "Hay #{duplicated.count} DNIs que están duplicados"
      else
        puts "No hay usuarios duplicados"
      end
    end

    desc "Eliminar los usuarios duplicados previamente eliminados"
    task deleted_duplicated_users: :environment do
      # Eliminamos definitivamente los usuarios que no han votado

      print "Eliminando usuarios..."
      deleted_users_ids_with_votes = Budget::Ballot.where(user_id: User.deleted.pluck(:id)).pluck(:user_id).uniq
      deleted_users_with_votes = User.deleted.where(id: deleted_users_ids_with_votes)

      deleted_users_with_votes.each do |duplicated_deleted_user|
        current_user = User.find_by_document_number(duplicated_deleted_user.document_number)
        current_user.take_votes_from(duplicated_deleted_user)
      end

      # Eliminamos los usuarios
      User.transaction do
        User.deleted.each do |user_to_delete|
          user_to_delete.really_destroy!
        end
      end
      puts " ✅"
      puts "Ejecución completada correctamente"
    end

    desc "Eliminar los usuarios duplicados con votos en los diferentes presupuestos"
    task duplicated_voters: :environment do
      print "Ejecutando script..."
      documents = User.all.map(&:document_number).compact
      documents.count - documents.uniq.count
      duplicated = documents.select{ |e| documents.count(e) > 1 }.uniq

      users_to_delete = []
      groups = User.where(document_number: duplicated).group_by(&:document_number).values
      groups_2 = groups.select { |g| g.count == 2 }
      puts
      print "Tratando usuarios duplicados"
      groups_2.each do |user_group|

        # Si alguno de los usuarios del grupo tiene email
        if user_group.map(&:email).compact.present?
          # Separamos los usuarios por los que tienen email y los que no
          users_with_email = user_group.select { |ug| ug.email.present? }
          users_without_email = user_group - users_with_email

          # Miramos si hay votos.
          if Budget::Ballot.where(user: user_group).present?
            case users_with_email.count
            when 1
              users_without_email.each do |user_without_email|
                  users_with_email.first.take_votes_from(user_without_email)
              end

              users_without_email.each do |user|
                  users_to_delete.push(user)
              end
            when 2
              last_voter = Array(Budget::Ballot.where(user: users_with_email).order(:created_at).last.user)
              with_email_to_delete = users_with_email - last_voter
              last_voter.first.take_votes_from(with_email_to_delete.first)

              with_email_to_delete.each do |user|
                  users_to_delete.push(user)
              end
              users_without_email.each do |user|
                  users_to_delete.push(user)
              end
            end

          # En caso de no haber votos se deja el último usuario con email
          else
            # Último usuario creado con email
            user_to_save = Array(users_with_email.max_by(&:created_at))

            users_with_email_to_delete = users_with_email - user_to_save

            users_without_email.each do |user|
                users_to_delete.push(user)
            end
            users_with_email_to_delete.each do |user|
                users_to_delete.push(user)
            end
          end

          # Si ningún usuario tiene email
        else
          users_voted = Budget::Ballot.where(user: user_group).map(&:user).uniq
          users_not_voted = user_group - users_voted

          case users_voted.count
          when 0
            # Si de los usuarios sin email no ha votado ninguno, se eliminan todos los usuarios excepto el último en ser creado.
            last_created = Array(user_group.max_by(&:created_at))
            other_users = user_group - last_created

            other_users.each do |user|
                users_to_delete.push(user)
            end
          when 1
            # Si de los usuarios sin email solo ha votado uno, se mantiene ese y se borran los demás.    
            users_not_voted.each do |user|
                users_to_delete.push(user)
            end
          when 2
            # De los usuarios sin email que tengan votos. Si hay 2 usuarios con votos se pasan del primero que haya votado al último.
            last_voter = Budget::Ballot.where(user: users_voted).order(:created_at).last.user
            first_voter = Budget::Ballot.where(user: users_voted).order(:created_at).first.user

            last_voter.take_votes_from(first_voter)
            users_to_delete.push(first_voter)
          end
        end
      end

      # Eliminando usuarios duplicados
      users_to_delete.each do |user|
        user.failed_census_calls.destroy_all if user.failed_census_calls.present?
        user.lock.destroy if user.lock.present?
        user.destroy
      end

      puts " ✅"
      print "Tratando usuarios triplicados"
      documents = User.all.map(&:document_number).compact
      documents.count - documents.uniq.count
      duplicated = documents.select{ |e| documents.count(e) > 1 }.uniq

      users_to_delete = []
      groups = User.where(document_number: duplicated).group_by(&:document_number).values
      groups_3 = groups.select { |g| g.count == 3 }

      groups_3.each do |user_group|
        # Si alguno de los usuarios del grupo tiene email
        if user_group.map(&:email).compact.present?
          # Separamos los usuarios por los que tienen email y los que no
          users_with_email = user_group.select { |ug| ug.email.present? }
          users_without_email = user_group - users_with_email

          # Miramos si hay votos.
          if Budget::Ballot.where(user: user_group).present?
            case users_with_email.count
            when 1
              users_without_email.each do |user_without_email|
                  users_with_email.first.take_votes_from(user_without_email)
              end

              users_without_email.each do |user|
                  users_to_delete.push(user)
              end
            when 2
              last_voter = Array(Budget::Ballot.where(user: users_with_email).order(:created_at).last.user)
              with_email_to_delete = users_with_email - last_voter
              last_voter.first.take_votes_from(with_email_to_delete.first)

              with_email_to_delete.each do |user|
                  users_to_delete.push(user)
              end
              users_without_email.each do |user|
                  users_to_delete.push(user)
              end
            when 3
              last_voter = Array(Budget::Ballot.where(user: users_with_email).order(:created_at).last.user)
              with_email_to_delete = users_with_email - last_voter

              with_email_to_delete.each do |user_w_email|
                  last_voter.first.take_votes_from(user_w_email)
              end

              with_email_to_delete.each do |user|
                  users_to_delete.push(user)
              end
              users_without_email.each do |user|
                  users_to_delete.push(user)
              end
            end

          # En caso de no haber votos se deja el último usuario con email
          else
              # Último usuario creado con email
              user_to_save = Array(users_with_email.max_by(&:created_at))

              users_with_email_to_delete = users_with_email - user_to_save

              users_without_email.each do |user|
                  users_to_delete.push(user)
              end
              users_with_email_to_delete.each do |user|
                  users_to_delete.push(user)
              end
          end

        # Si ningún usuario tiene email
        else
          users_voted = Budget::Ballot.where(user: user_group).map(&:user).uniq
          users_not_voted = user_group - users_voted

          case users_voted.count
          when 0
            # Si de los usuarios sin email no ha votado ninguno, se eliminan todos los usuarios excepto el último en ser creado.
            last_created = Array(user_group.max_by(&:created_at))
            other_users = user_group - last_created

            other_users.each do |user|
                users_to_delete.push(user)
            end
          when 1
            # Si de los usuarios sin email solo ha votado uno, se mantiene ese y se borran los demás.    
            users_not_voted.each do |user|
                users_to_delete.push(user)
            end
          when 2
            # De los usuarios sin email que tengan votos. Si hay 2 usuarios con votos se pasan del primero que haya votado al último.
            last_voter = Budget::Ballot.where(user: users_voted).order(:created_at).last.user
            first_voter = Budget::Ballot.where(user: users_voted).order(:created_at).first.user

            last_voter.take_votes_from(first_voter)
            first_voter.each do |user|
                users_to_delete.push(user)
            end
          when 3
            # De los usuarios sin email que tengan votos. Si hay 3 usuarios se busca el que haya votado último y se transfieren los votos de los otros dos
            last_voter = Array(Budget::Ballot.where(user: users_voted).order(:created_at).last.user)
            other_voters = users_voted - last_voter
            other_voters.each do |other_voter|
                last_voter.first.take_votes_from(other_voter)
            end
            (other_voters).each do |user|
                users_to_delete.push(user)
            end
          end
        end
      end

      # Eliminando usuarios triplicados
      users_to_delete.each do |user|
        user.failed_census_calls.destroy_all if user.failed_census_calls.present?
        user.lock.destroy if user.lock.present?
        user.destroy
      end

      puts " ✅"
      print "Tratando usuarios cuadruplicados"
      documents = User.all.map(&:document_number).compact
      documents.count - documents.uniq.count
      duplicated = documents.select{ |e| documents.count(e) > 1 }.uniq

      users_to_delete = []
      groups = User.where(document_number: duplicated).group_by(&:document_number).values
      groups_4 = groups.select { |g| g.count == 4 }

      groups_4.each do |user_group|
          # Si alguno de los usuarios del grupo tiene email
        if user_group.map(&:email).compact.present?
          # Separamos los usuarios por los que tienen email y los que no
          users_with_email = user_group.select { |ug| ug.email.present? }
          users_without_email = user_group - users_with_email

          # Miramos si hay votos.
          if Budget::Ballot.where(user: user_group).present?
            case users_with_email.count
            when 1
              users_without_email.each do |user_without_email|
                users_with_email.first.take_votes_from(user_without_email)
              end

              users_without_email.each do |user|
                users_to_delete.push(user)
              end
            when 2
              last_voter = Array(Budget::Ballot.where(user: users_with_email).order(:created_at).last.user)
              with_email_to_delete = users_with_email - last_voter
              last_voter.first.take_votes_from(with_email_to_delete.first)

              with_email_to_delete.each do |user|
                users_to_delete.push(user)
              end
              users_without_email.each do |user|
                users_to_delete.push(user)
              end
            when 3, 4
              last_voter = Array(Budget::Ballot.where(user: users_with_email).order(:created_at).last.user)
              with_email_to_delete = users_with_email - last_voter

              with_email_to_delete.each do |user_w_email|
                last_voter.first.take_votes_from(user_w_email)
              end

              with_email_to_delete.each do |user|
                users_to_delete.push(user)
              end
              users_without_email.each do |user|
                users_to_delete.push(user)
              end
            end

          # En caso de no haber votos se deja el último usuario con email
          else
            # Último usuario creado con email
            user_to_save = Array(users_with_email.max_by(created_at))

            users_with_email_to_delete = users_with_email - user_to_save

            users_without_email.each do |user|
              users_to_delete.push(user)
            end
            users_with_email_to_delete.each do |user|
              users_to_delete.push(user)
            end
          end

        # Si ningún usuario tiene email
        else
          users_voted = Budget::Ballot.where(user: user_group).map(&:user).uniq
          users_not_voted = user_group - users_voted

          case users_voted.count
          when 0
            # Si de los usuarios sin email no ha votado ninguno, se eliminan todos los usuarios excepto el último en ser creado.
            users_to_delete += users_not_voted
          when 1
            # Si de los usuarios sin email solo ha votado uno, se mantiene ese y se borran los demás.    
            users_not_voted.each do |user|
              users_to_delete.push(user)
            end
          when 2
            # De los usuarios sin email que tengan votos. Si hay 2 usuarios con votos se pasan del primero que haya votado al último.
            last_voter = Budget::Ballot.where(user: users_voted).order(:created_at).last.user
            first_voter = Budget::Ballot.where(user: users_voted).order(:created_at).first.user

            last_voter.take_votes_from(first_voter)
            first_voter.each do |user|
              users_to_delete.push(user)
            end
          when 3, 4
            # De los usuarios sin email que tengan votos. Si hay 3 usuarios se busca el que haya votado último y se transfieren los votos de los otros dos
            last_voter = Array(Budget::Ballot.where(user: users_voted).order(:created_at).last.user)
            other_voters = users_voted - last_voter
            other_voters.each do |other_voter|
              last_voter.first.take_votes_from(other_voter)
            end
            other_voters.each do |user|
              users_to_delete.push(user)
            end
            users_to_delete += users_not_voted
          end
        end
      end

      # Eliminando usuarios cuadruplicados
      users_to_delete.each do |user|
        user.failed_census_calls.destroy_all if user.failed_census_calls.present?
        user.lock.destroy if user.lock.present?
        user.destroy
      end

      puts " ✅"
      Rake::Task["data:budgets:deleted_duplicated_users"].invoke
    end

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
