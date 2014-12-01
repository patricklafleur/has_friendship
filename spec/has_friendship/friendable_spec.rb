require 'rails_helper'

describe Friendable do

  let(:user){ Friendable.create(name: 'Jessie') }
  let(:friend){ Friendable.create(name: 'Heisenberg') }

  describe "association" do
    it { should have_many(:friendships).dependent(:destroy) }
    it { should have_many(:friends).through(:friendships).conditions(status: 'accepted') }
    it { should have_many(:requested_friends).through(:friendships).conditions(status: 'requested') }
    it { should have_many(:pending_friends).through(:friendships).conditions(status: 'pending') }
  end

  describe "instance methods" do
    
    describe "#friend_request" do
      it "should be provided" do
        expect(user).to respond_to(:friend_request)
      end

      context "when user requests friendship to itself" do
        it "should not create Friendship" do
          expect { 
            user.friend_request(user)
          }.to change(Friendship, :count).by(0)
        end
      end

      context "when user requests friendship to friend" do
        context "if friendship already exists" do
          it "should not create Friendship" do
            create_friendship(user, friend)

            expect {
              user.friend_request(friend)
            }.to change(Friendship, :count).by(0)
          end
        end

        context "if friendship does not yet exist" do
          it "should create 2 Friendship records" do
            expect { 
              user.friend_request(friend)
            }.to change(Friendship, :count).by(2)
          end

          describe "Friendship from user to friend" do
            before :each do
              user.friend_request(friend)
              @friendship = Friendship.find_by(friendable_id: user.id, friendable_type: user.class.base_class.name, friend_id: friend.id)
            end

            it "should be created" do
              expect(@friendship).to be_present
            end

            it "should have status: 'pending'" do
              expect(@friendship.status).to eq 'pending'
            end
          end

          describe "Friendship from friend to user" do
            before :each do
              user.friend_request(friend)
              @friendship = Friendship.find_by(friendable_id: friend.id, friendable_type: friend.class.base_class.name, friend_id: user.id)
            end

            it "should be created" do
              expect(@friendship).to be_present
            end

            it "should have status: 'requested'" do
              expect(@friendship.status).to eq 'requested'
            end
          end
        end
      end
    end

    describe "#accept_request" do
      it "should be provided" do
        expect(user).to respond_to(:accept_request)
      end

      context "when there is no such request" do
        it "raises error" do
          expect { 
            user.accept_request(friend)
          }.to raise_error
        end
      end

      context "when there is a request" do
        it "should update the status of pending Friendship to 'accepted'" do
          create_request(user, friend)
          friend.accept_request(user)
          friendship = find_friendship_record(user, friend) # status: 'pending'

          expect(friendship.status).to eq 'accepted'
        end

        it "should update the status of requested Friendship to 'accepted'" do
          create_request(user, friend)
          friend.accept_request(user)
          friendship = find_friendship_record(friend, user) #status: 'requested'

          expect(friendship.status).to eq 'accepted'
        end
      end
    end
  end
end